class SalesforceLeadWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    SalesforceApi.create_lead(user)
  end
end
