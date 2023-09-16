class PasswordEmailWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.reset_password(user).deliver_now
  end
end