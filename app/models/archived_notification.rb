class ArchivedNotification < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  belongs_to :user
  belongs_to :entry

  def self.add_or_increment(user, entry, for_notificable)
    archived_notification = ArchivedNotification.where(user_id: user.id, entry_id: entry.id, for_notificable: for_notificable).first_or_initialize
    archived_notification.increment(:count).save!
    return archived_notification
  end

  def message
    case for_notificable
      when 'comment_on_entry'
        "Your entry was commented on #{count} #{pluralize(count, 'time')}."
      when 'like_on_entry'
        "Your entry received #{count} #{pluralize(count, 'like')}."
      when 'like_on_comment'
        "Your comment received #{count} #{pluralize(count, 'like')}."
      when 'mention_in_entry'
        "You were mentioned #{count} #{pluralize(count, 'time')} in an entry."
      when 'mention_in_comment'
        "You were mentioned #{count} #{pluralize(count, 'time')} at the comments to post."
      else
        raise "wrong notificable type"
    end
  end
end
