namespace :intercom do
  desc 'Process users in Intercom queue'
  task :process_queue => :environment do
    IntercomQueueWorker.perform_async
  end
end
