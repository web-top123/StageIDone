namespace :cancel_subscriptions do
  desc "Cancel subscription whose quntity is 0 and plan is active"
  task :cancel_customer_subscription => :environment do
    file = "tmp/subscriptions_cancel.csv"
    csv = CSV.read(file)
    CSV.foreach(file, :headers => true) do |row|
      puts "Customer #{row}"
      begin
        Stripe::Subscription.retrieve(row["id"]).delete()
      rescue Stripe::InvalidRequestError => e
        Raven.capture_exception(e)
      end
    end
  end
end