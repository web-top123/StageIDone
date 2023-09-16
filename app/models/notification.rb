class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :entry
  belongs_to :author, -> { with_deleted }, :class_name => 'User'

  def message
    case for_notificable
      when 'comment_on_entry'
        "#{author.full_name_or_something_else_identifying} has commented on your entry."
      when 'like_on_entry'
        "#{author.full_name_or_something_else_identifying} liked your entry."
      when 'like_on_comment'
        "#{author.full_name_or_something_else_identifying} liked your comment."
      when 'mention_in_entry'
        "You were mentioned by #{author.full_name_or_something_else_identifying} in an entry."
      when 'mention_in_comment'
        "You were mentioned by #{author.full_name_or_something_else_identifying} in a comment."
      else
        raise "wrong notificable type"
    end
  end

  def archive!
    self.destroy!
    ArchivedNotification.add_or_increment(user, entry, for_notificable)
  end

  def self.add(user, entry, for_notificable, author)
    team_membership = user.team_memberships.find_by(team_id: entry.team.id)

    if team_membership && team_membership.subscribed_notifications.include?('mention')
      Notification.create(user: user, for_notificable: for_notificable, entry: entry, author: author)
    else
      ArchivedNotification.add_or_increment(user, entry, for_notificable)
    end  
  end

  def self.archive!(user, date, team_id)
    self.eager_load(:entry) .where(user: user,
      entries: {occurred_on: date, team_id: team_id}).each do |notification|
     
      notification.archive!
    end
  end
  
end
