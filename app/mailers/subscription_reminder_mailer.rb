class SubscriptionReminderMailer < ApplicationMailer
  def send_renewal_email(upcoming_invoice, organization, owner)
    @upcoming_invoice = upcoming_invoice
    @organization = organization
    @owner = owner

    mail to: @owner.email_address, subject: "Subscription renewal notice", from: "I Done This <support@idonethis.com>"
  end
end
