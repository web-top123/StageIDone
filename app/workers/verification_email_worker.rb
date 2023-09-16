class VerificationEmailWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.verify_user(user).deliver_now
  end
end
