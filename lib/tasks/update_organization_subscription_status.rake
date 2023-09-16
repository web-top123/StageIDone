namespace :update_organization_subscription_status do
  desc "Update Organization subscription status from stripe"
  task :update_subscription => :environment do
    org_count = 0
    Organization.all.each do |organization|
      begin
        customer = Stripe::Customer.retrieve(organization.stripe_customer_token)
        if customer.present?
          subscription = customer[:subscriptions]
          if subscription.present? && subscription.any?
            subscription_status = subscription[:data]&.first&.status
            organization.stripe_subscription_status = subscription_status
          else
            organization.stripe_subscription_status = 'canceled'
          end
        else
          organization.stripe_subscription_status = 'canceled'
        end
        organization.save
        org_count += 1
      rescue Stripe::InvalidRequestError => e
        Raven.capture_message "Org##{organization.id}: failed to retrieve Stripe Customer #{organization.stripe_customer_token}",
                              extra: { errors: e }
      end
    end
    puts "Org count : #{org_count}"
  end
end
