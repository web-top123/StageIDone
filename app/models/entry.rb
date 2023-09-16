class Entry < ActiveRecord::Base
  include IdtIntercom::Entry
  include RailsSortable::Model
  set_sortable :sort, without_updating_timestamps: true

  validates :body, presence: true
  # 'Occurred_on' is the day (in user time zone) this entry is attached to.
  # If I enter a goal for tomorrow, its 'occurred_on' will be `Date.tomorrow`.
  validates :occurred_on, presence: true
  validates :status, inclusion: {in: %w(done goal blocked)}, allow_nil: true # TODO: allow_nil should really be false. status should be required or default to done.

  belongs_to :user, -> { with_deleted }, counter_cache: true
  belongs_to :team

  has_many :tags, through: :entry_tags
  has_many :notifications, dependent: :destroy
  has_many :archived_notifications, dependent: :destroy
  has_many :entry_tags, dependent: :destroy
  has_many :mentions, as: :mentionable, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy

  has_one :prompting_goal, -> { where(status: 'goal') }, foreign_key: 'completed_entry_id', class_name: 'Entry'

  scope :antichronologically, -> { order('entries.created_at desc') }
  scope :chronologically, -> { order('entries.created_at asc') }
  scope :order_by_priority, -> { order(:sort) }

  scope :created_since_time, -> (t) { where('entries.created_at > ? AND entries.created_at < ?', t, Time.current) }

  scope :for_period, -> (b,e) { where("entries.occurred_on >= ? and entries.occurred_on <= ?", b, e) }
  scope :for_month, -> (t) { for_period(t.beginning_of_month.to_date, t.end_of_month.to_date) }
  scope :for_day, -> (t) { where(occurred_on: t.to_date) }

  def self.for_month_group_by_user_and_occurred_on(t)
    entries_by_occured_on_by_user = {}
    users_with_entries = {}
    for_month(t).group_by { |entry_elem| entry_elem.occurred_on }.
      each_pair do |occured_on, day_entries|
        entries_by_occured_on_by_user[occured_on.to_s] = {}
        day_entries_by_user = day_entries.group_by { |entry_elem| entry_elem.user }
        day_entries_by_user.each_pair do |user, user_day_entries|
          users_with_entries[user.id] ||= { id: user.id, portrait_thumbnail_url: user.portrait.thumbnail.url, profile_color: user.profile_color, full_name_or_something_else_identifying: user.full_name_or_something_else_identifying }
          entries_by_occured_on_by_user[occured_on.to_s][user.id] = user_day_entries
        end
      end
     { entries: entries_by_occured_on_by_user, users: users_with_entries }
  end

  scope :for_organization, -> (o) { joins(:team).where('teams.organization_id = ?', o.id) }
  scope :for_team, -> (t) { where(team_id: t.id) }
  scope :for_status, -> (s) { where(status: s) }

  # goal specific
  scope :outstanding_goals, -> { where(status: 'goal').where(completed_on: nil).where(archived_at: nil) }
  scope :outstanding_blocks, -> { where(status: 'blocked').where(completed_on: nil).where(archived_at: nil) }
  scope :outstanding_entries, -> { where(status: %w[blocked goal]).where(completed_on: nil).where(archived_at: nil) }

  scope :dones,    -> { where(status: 'done') }
  scope :goals,    -> { where(status: 'goal') }
  scope :blockers, -> { where(status: 'blocked') }
  scope :tips,    -> { where(tip: 'true') }
  scope :not_tips,    -> { where(tip: 'false') }

  after_save :save_entities
  after_update :post_update_webhook
  after_commit :post_create_webhook, on: :create
  after_commit :post_to_slack, on: :create
  before_save :create_hash_id_if_necessary
  before_save :enstatus_entry
  before_destroy :reset_completion_information_if_necessary

  # This is mostly around for migration purposes, we don't want to parse entities
  # when migrating old entries
  attr_accessor :skip_parsing_body

  def self.create_without_parsing(params)
    e = Entry.new(params)
    e.skip_parsing_body = true
    e.save
    e
  end

  def to_param
    self.hash_id
  end

  def pretty_format
    self.as_json(
      only: [:hash_id, :body, :status, :occurred_on, :completed_on, :archived_at, :created_at, :updated_at],
      include: [
        {team: {only: [:hash_id, :name]}},
        {user: {only: [:hash_id, :full_name, :email_address]}}
      ]
    )
  end

  def body_formatted
    EntryParser.parse(self)
  end

  def as_json(options = nil)
    super(options.merge(methods: :body_formatted))
  end

  # Processes and saves entities related to an entry, like tags and mentions
  def save_entities
    return if skip_parsing_body

    entities   = EntryParser.extract_entities(body)
    tags       = entities.select{|e| !e[:hashtag].nil? }.map{|t| t[:hashtag].downcase }
    nicknames  = entities.select{|e| !e[:screen_name].nil? }.map{|n| n[:screen_name] }

    known_tags = Tag.where(name: tags)
    known_tag_names = known_tags.map(&:name)
    tags.each do |tag|
      unless known_tag_names.include?(tag)
        known_tags << Tag.create(name: tag.downcase)
        known_tag_names << tag
      end
    end

    known_tags.each do |known_tag|
      entry_tags.find_or_create_by(tag: known_tag)
    end

    if !team.personal?
      nicknames.each do |nickname|
        user = team.active_users.where(go_by_name: nickname).first
        mentions.find_or_create_by(user: user) if user
      end
    end
  end

  # TODO: Rewrite this into a has_one as well
  def completed_entry
    return Entry.none unless self.completed_entry_id.present?
    @completed_entry ||= Entry.where(id: self.completed_entry_id, status: 'done').first
  end

  def completed?
    (self.status == 'done') || (self.completed_entry.present?)
  end

  def completed_same_day?
    (self.status == 'goal') && self.completed_entry.present? && (self.completed_on == self.occurred_on)
  end

  def archived?
    self.archived_at
  end

  def mark_done!(day)
    return unless !completed?

    @completed_entry = self.dup
    @completed_entry.created_by = 'app'
    @completed_entry.status = 'done'
    @completed_entry.occurred_on = day
    @completed_entry.save!

    self.completed_on = day
    self.completed_entry_id = @completed_entry.id
    save!
  end

  def completed_on_for_export
    return completed_on if self.completed_on.present?
    return occurred_on if self.status == 'done'
    return nil
  end

  def self.to_csv
    CSV.generate do |csv|
      csv << [
        'user_email_address',
        'status',
        'body',
        'occurred_on',
        'completed_on',
        'created_at',
        'archived_at'
      ]

      all.each do |entry|
        csv << [
          entry.user.try(:email_address),
          entry.status,
          entry.body,
          entry.occurred_on,
          entry.completed_on_for_export,
          entry.created_at
        ]
      end
    end
  end

  private

  def post_to_slack
    return if skip_parsing_body
    links = IntegrationLink.where(team: self.team, integration_type: 'slack-poster')
    links.each do |link|
      SlackEntryPosterWorker.perform_async(self.id, link.id)
    end
  end

  # Enstatusing an entry means that we override whatever status was given based
  # on the simple rule of the first two to three characters of the body [ ] [x] [√]
  # This is because most ways to create an entry (for the time being) will
  # default to done, but we might want to change that default depending on the
  # body (such as by email).
  def enstatus_entry
    return if skip_parsing_body
    reg_match = body.match(/^\s*(\[[\sxX√]?\]|!)\s*/)
    return unless reg_match
    str = reg_match[0].strip
    if str == '[]' || str == '[ ]'
      self.status = 'goal'
    elsif str == '[x]' || str == '[X]' || str == '[√]'
      self.status = 'done'
    elsif str == '!'
      self.status = 'blocked'
    end
    self.body = body[reg_match[0].length .. -1]
  end

  def create_hash_id_if_necessary
    if self.respond_to?('hash_id') && (self.new_record? || self.hash_id.blank?)
      self.hash_id = Digest::SHA1.hexdigest([Time.now, rand].join)
    end
  end

  def reset_completion_information_if_necessary
    if self.status == 'done'
      ce = Entry.where(completed_entry_id: self.id).first
      if ce
        ce.completed_entry_id = nil
        ce.completed_on = nil
        ce.save
      end
    end

    true
  end

  def post_update_webhook
    post_webhook('updated')
  end

  def post_create_webhook
    post_webhook('created')
  end

  def post_webhook(event)
    return if skip_parsing_body
    Hook.where(team: self.team).all.each do |hook|
      HookWorker.perform_async(hook.id, self.id, event)
    end
  end
end
