class VerifyAlternateEmailWorker
  include Sidekiq::Worker

  def perform(alternate_email_address_id)
    alternate_email_address = AlternateEmail.find(alternate_email_address_id)
    UserMailer.verify_alternate_email(alternate_email_address).deliver_now
  end
end
