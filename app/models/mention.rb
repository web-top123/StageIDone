class Mention < ActiveRecord::Base
  belongs_to :user # The user is the one being mentioned
  belongs_to :mentionable, polymorphic: true # The thing user is mentioned in, either Entry or Reaction right now
  after_commit :send_notification, on: :create

  private

  def send_notification
    author = mentionable.user

    return true if self.user == author # don't send if the mentioner is mentioning themselves
    return true if (mentionable_type == 'Reaction') && (mentionable.reactable.user == self.user) # don't send if the person will already be notified

    if mentionable_type == 'Reaction'
      entry = mentionable.reactable
      mention_type = 'comment'
    else
      entry = mentionable
      mention_type = 'entry'
    end

    Notification.add(self.user, entry, "mention_in_#{mention_type}", author)

    NotificationEmailWorker.perform_async(:mention, self.id)

    true
  end
end
