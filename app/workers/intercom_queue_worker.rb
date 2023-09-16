class IntercomQueueWorker
  include Sidekiq::Worker

  def perform
    # process in batches of 100 for intercom
    IntercomQueue.where(processed_at: nil).joins(:user).eager_load(:user).find_in_batches(batch_size: 100) do |intercom_queues|
      IntercomApi.upsert_users(intercom_queues.map(&:user))
      intercom_queues.each(&:mark_processed!)
    end
    IntercomQueue.clear!
  end
end
