class IntercomUserWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    IntercomApi.upsert_user(user)
  end
end
