class SubscriptionReminderWorker
  include Sidekiq::Worker

  def perform(upcoming_invoice, organization, owner)
    SubscriptionReminderMailer.send_renewal_email(upcoming_invoice, organization, owner).deliver_now
  end
end
