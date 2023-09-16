class NotificationEmailWorker
  include Sidekiq::Worker

  sidekiq_retries_exhausted do |msg|
    err = "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    Rails.logger.error err
    Raven.capture_message err
  end

  def perform(notification_type, notification_id)
    case notification_type.to_sym
    when :mention
      mention = Mention.find(notification_id)
      NotificationMailer.mention_notification(mention).deliver_now
    when :comment
      comment = Reaction.find(notification_id)
      NotificationMailer.comment_notification(comment).deliver_now
    else
      Raven.capture "Failed to perform notification for #{ notification_type }: #{ notification_id }"
    end
  rescue ActiveRecord::RecordNotFound
    # mention or comment has been deleted
  end
end
