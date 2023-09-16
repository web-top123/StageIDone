class TeamMembership < ActiveRecord::Base
  acts_as_paranoid

  DAYS = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
  }

  bitmask :frozen_digest_days,
    :as => [DAYS.key(0),
            DAYS.key(1),
            DAYS.key(2),
            DAYS.key(3),
            DAYS.key(4),
            DAYS.key(5),
            DAYS.key(6)]
  bitmask :frozen_reminder_days,
    :as => [DAYS.key(0),
            DAYS.key(1),
            DAYS.key(2),
            DAYS.key(3),
            DAYS.key(4),
            DAYS.key(5),
            DAYS.key(6)]

  belongs_to :team
  belongs_to :user

  validates :email_reminder_seconds_since_midnight, presence: true, numericality: true
  validates :email_digest_seconds_since_midnight, presence: true, numericality: true
  validates :user_id, presence: true, uniqueness: {scope: :team_id}
  validates :team_id, presence: true, uniqueness: {scope: :user_id}

  # If digest/reminder email days are frozen then frozen_reminder_day/frozen_digest_days will
  # have values
  scope :not_both_email_days_frozen?, -> { without_frozen_reminder_days || without_frozen_digest_days }
  # By default: inactivity is 1 week without activity
  scope :with_inactive_entries, -> {
    joins("LEFT JOIN entries ON team_memberships.user_id = entries.user_id AND team_memberships.team_id = entries.team_id").
      where("team_memberships.created_at < ?", 1.week.ago).
      group("team_memberships.id, team_memberships.user_id, team_memberships.team_id").
      having("MAX(entries.created_at) < ? OR MAX(entries.created_at) IS NULL", 1.week.ago)
  }
  scope :active, -> { where(removed_at: nil) }
  scope :removed, -> { where.not(removed_at: nil) }
  scope :reminder_subscribed, -> { where("reminder_sunday  OR
                                         reminder_monday  OR
                                         reminder_tuesday  OR
                                         reminder_wednesday  OR
                                         reminder_thursday  OR
                                         reminder_friday  OR
                                         reminder_saturday")}

  scope :digest_subscribed, -> { where("digest_sunday  OR
                                         digest_monday  OR
                                         digest_tuesday  OR
                                         digest_wednesday  OR
                                         digest_thursday  OR
                                         digest_friday  OR
                                         digest_saturday")}

  scope :subscribed, -> { where("reminder_sunday  OR
                                 reminder_monday  OR
                                 reminder_tuesday  OR
                                 reminder_wednesday  OR
                                 reminder_thursday  OR
                                 reminder_friday  OR
                                 reminder_saturday OR
                                 digest_sunday  OR
                                 digest_monday  OR
                                 digest_tuesday  OR
                                 digest_wednesday  OR
                                 digest_thursday  OR
                                 digest_friday  OR
                                 digest_saturday")}
  scope :reminder_not_in_sending, -> {where(reminder_status: nil)}
  scope :digest_not_in_sending, -> {where(digest_status: nil)}

  scope :digest_should_be_sent_in,   -> (time) {digest_not_in_sending.where("next_digest_time < ?",     time).active }
  scope :reminder_should_be_sent_in, -> (time) {reminder_not_in_sending.where("next_reminder_time < ?", time).active }

  scope :alphabetically, -> { includes(:user).order('users.sorting_name asc') }
  scope :active_at, -> (date) { where("removed_at >= ? or removed_at IS NULL", date.beginning_of_day) }

  scope :notify_by_digest_email, -> { eager_load(:user).
                                      subscribed.
                                      where('digest_status != ? OR digest_status IS NULL', 'inqueue').
                                      active }

  scope :notify_by_reminder_email, -> { eager_load(:user).
                                        subscribed.
                                        where('reminder_status != ? OR reminder_status IS NULL', 'inqueue').
                                        active }

  before_validation -> {update_next_emails_send(:digest)}
  before_validation -> {update_next_emails_send(:reminder)}

  before_save do |team_membership|
    team_membership.subscribed_notifications.reject! {|r| r.blank? }
  end
  
  def update_next_emails_send(mailer_type)
    
    validate_mailer_type(mailer_type)

    return true if self.send("#{mailer_type}_status") != nil

    # if the user has no days selected
    if !days[mailer_type].any?
      return self.send("next_#{mailer_type}_time=", nil)
    end

    last_sent = self.send("email_#{mailer_type}_last_sent_at")
    if last_sent.present?
      # next day - next day after last send
      next_day = last_sent.in_time_zone(user.time_zone).beginning_of_day + 1.day
    else
      # or after created_at, if there no emails sent before
      created = created_at || Time.current
      next_day = created.in_time_zone(user.time_zone).beginning_of_day + 1.day
    end

    # if the user doesn't have the next day selected, find the next day they want an email
    if !days[mailer_type][next_day.wday]
      next_day += days[mailer_type].rotate(next_day.wday).index(true).days
    end
    # add time, when user wants to get email
    next_day += send("email_#{mailer_type}_seconds_since_midnight").seconds
    self.send("next_#{mailer_type}_time=", next_day.utc)
  end

  def self.email_time_options
    #0 second = 12am. 85500 = 11:45. 900s=15m
    0.step(85500,900).map do |seconds_since_midnight|
      [Time.at(seconds_since_midnight).utc.strftime("%l:%M%P"),seconds_since_midnight]
    end
  end

  def digest_subscribed?
    digest_days.any?
  end

  def reminder_subscribed?
    reminder_days.any?
  end

  def subscribed?
    reminder_subscribed? || digest_subscribed?
  end

  def remove!
    self.touch(:removed_at)
  end

  def join!
    self.removed_at = nil
    self.save!
  end

  def active?
    !self.removed_at?
  end

  def inactive?
    !self.active?
  end

  def subscribe_comments_notification
    self.subscribed_notifications.push('comment') unless self.subscribed_notifications.include?('comment')
    self.save!
  end

  def unsubscribe_comments_notification
    self.subscribed_notifications.delete(
      'comment'
    )
    self.save!
  end

  def subscribe_mentions_notification
    self.subscribed_notifications.push('mention') unless self.subscribed_notifications.include?('mention')
    self.save!
  end

  def unsubscribe_mentions_notification
    self.subscribed_notifications.delete(
      'mention'
    )
    self.save!
  end


  def unsubscribe_digests!
    self.update_attributes(
      digest_sunday: false,
      digest_monday: false,
      digest_tuesday: false,
      digest_wednesday: false,
      digest_thursday: false,
      digest_friday: false,
      digest_saturday: false)
  end

  def unsubscribe_reminders!
    self.update_attributes(
      reminder_sunday: false,
      reminder_monday: false,
      reminder_tuesday: false,
      reminder_wednesday: false,
      reminder_thursday: false,
      reminder_friday: false,
      reminder_saturday: false)
  end

  def unsubscribe_assign_task_reminders!
    self.update_attributes(assign_task_reminder_status: false)
  end

  def unsubscribe_from_all!
    unsubscribe_digests!
    unsubscribe_reminders!
  end

  def digest_days
    [digest_sunday,
    digest_monday,
    digest_tuesday,
    digest_wednesday,
    digest_thursday,
    digest_friday,
    digest_saturday]
  end

  def reminder_days
    [reminder_sunday,
    reminder_monday,
    reminder_tuesday,
    reminder_wednesday,
    reminder_thursday,
    reminder_friday,
    reminder_saturday]
  end

  # Save current email notification settings of mailer_type
  # into frozen_#{mailer_type}_days field
  def freeze_email_days(mailer_type)
    send("#{mailer_type}_days").each_with_index do |should_send, idx|
      send("frozen_#{mailer_type}_days").send('<<', DAYS.key(idx)) if should_send
    end
    save!
  end

  # Restore frozen_#{mailer_type}_days field back to
  # email notification settings
  def unfreeze_email_days(mailer_type)
    DAYS.keys.each do |day_of_week|
      send("#{mailer_type}_#{day_of_week}=", send("frozen_#{mailer_type}_days?", day_of_week))
    end
    # Reset to frozen email days to empty
    send("frozen_#{mailer_type}_days=", [])
    save!
  end

  def frozen_email_days(mailer_type)
    DAYS.keys.map { |day_of_week| send("frozen_#{mailer_type}_days?", day_of_week) }
  end

  def throttle_email_days
    freeze_notifications_and_set_once_a_week_email(:digest) if digest_days.select { |e| e }.size > 1
    freeze_notifications_and_set_once_a_week_email(:reminder) if reminder_days.select { |e| e }.size > 1
  end

  def unthrottle_email_days
    unfreeze_email_days(:reminder)
    unfreeze_email_days(:digest)
  end

  def freeze_notifications_and_set_once_a_week_email(mailer_type)
    freeze_email_days(mailer_type)
    send("unsubscribe_#{mailer_type}s!")
    # Set only weekdays
    weekly_email_day = DAYS.key(rand(1..5))
    send("#{mailer_type}_#{weekly_email_day}=", true)
    save!
  end

  private

  def days
    {reminder: reminder_days, digest: digest_days}
  end

  # This function exists because we might have a new user who has never received
  # a particular email before so we want to say that the next email they get is
  # "today". However, if they have gotten an email from us already, we should
  # send the next one one day from the last

  def validate_mailer_type(type)
    raise "Wrong mailer_type passed. Should be :digest or :reminder, got :#{type}" unless[:digest, :reminder].include?(type)
  end
end
