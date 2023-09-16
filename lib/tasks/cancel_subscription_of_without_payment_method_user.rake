namespace :cancel_subscription_of_without_payment_method_user do
  desc "Cancel subscription if the payment methods are empty"
  task :cancel_subscription => :environment do
    org_count = 0
    Organization.all.each do |organization|
      begin
        customer = Stripe::Customer.retrieve(organization.stripe_customer_token)
        if customer.present?
          subscription = customer[:subscriptions]
          if subscription.present? && subscription.any?
            subscription_status = subscription[:data]&.first&.status
            subscription_id = subscription[:data]&.first&.id

            if (subscription_status == 'past_due' || subscription_status == 'unpaid') && customer.sources.blank?
              canceled_sub = Stripe::Subscription.retrieve(subscription_id).delete()
              if canceled_sub.present?
                organization.stripe_subscription_status = canceled_sub.status
                organization.save
                org_count += 1
                puts "Organization : #{organization.id}"
              else
                Raven.capture_message "Org##{organization.id}: failed to cancel subscription of Stripe Customer #{organization.stripe_customer_token}"
              end
            end
          end 
        end
      rescue Stripe::InvalidRequestError => e
        Raven.capture_message "Org##{organization.id}: failed to cancel subscription of Stripe Customer #{organization.stripe_customer_token}",
                              extra: { errors: e }
      end
    end
    puts "Org count : #{org_count}"
  end
end
