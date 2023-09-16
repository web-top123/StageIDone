namespace :plan_upgrade do
  desc "set all legacy plans to standard (small)"
  task run: :environment do
    organization_id = ENV.fetch('ORGANIZATION_ID', nil)
    mode            = ENV.fetch('MODE', 'check')

    file = "tmp/subscription_update_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
    csv = CSV.open(file,"w")

    csv << ['name',
            'id',
            'created_at',
            'stripe_created_at',
            'billing_email_address',
            'stripe_id',
            'active_users',
            'organization_subscription_status',
            'trial_ends_at',
            'on_trial?',
            'plan_level',
            'plan_interval',
            'current_subscription_quantity',
            'current_subscription_amount',
            'current_subscription_plan_id',
            'current_subscription_interval',
            'current_subscription_status',
            'billable_card_on_file',
            'new_subscription_plan_id',
            'new_subscription_amount',
            'trial_ends_at_should_be_fixed?',
            'action'
          ]

    exclude_orgs = [
      4978, # Airbnb
      4704, # Shopify
      4893  # TripAdvisor
    ]

    if organization_id.present?
      organizations = Organization.where(id: organization_id)
    else
      organizations = Organization
    end

    organizations.find_each do |organization|
      puts "Processing #{organization.name} : #{organization.id}"

      stripe_created_at = Time.zone.at(organization.stripe_customer.created)
      action = 'checked'

      if organization.stripe_customer.subscriptions.any?
        subscription                  = organization.stripe_customer.subscriptions.first
        current_subscription_quantity = subscription.quantity
        current_subscription_amount   = subscription.plan.amount
        current_subscription_interval = subscription.plan.interval
        current_subscription_plan_id  = subscription.plan.id
        current_subscription_status   = subscription.status

        trial_ends_at_should_be_fixed = current_subscription_status == 'active' && stripe_created_at < 14.days.ago && organization.on_trial?

        level, interval = AppSetting.stripe_plan_id_to_internal(current_subscription_plan_id)

        if AppSetting.stripe_id_for_plan_level_and_interval(level, interval).nil? # legacy plan
          level = current_subscription_plan_id == 'Invoicing_yearly_v1' ? "invoice" : "small"
          new_subscription_plan_id = AppSetting.stripe_id_for_plan_level_and_interval(level, "#{current_subscription_interval}ly")
          new_plan = Stripe::Plan.retrieve(new_subscription_plan_id)
          new_subscription_amount = new_plan.amount

          if mode == 'fix' && !exclude_orgs.include?(organization.id)
            plan_level, plan_interval  = AppSetting.stripe_plan_id_to_internal(new_subscription_plan_id)
            organization.plan_level    = plan_level
            organization.plan_interval = plan_interval
            organization.save!
            action = 'updated'
          end

        end
      end

      if exclude_orgs.include?(organization.id)
        action << " and EXCLUDED"
      end

      csv << [organization.name,
              organization.id,
              organization.created_at,
              stripe_created_at,
              organization.billing_email_address,
              organization.stripe_customer_token,
              organization.active_users.count,
              organization.stripe_subscription_status,
              organization.trial_ends_at,
              organization.on_trial?,
              organization.plan_level,
              organization.plan_interval,
              current_subscription_quantity,
              current_subscription_amount,
              current_subscription_plan_id,
              current_subscription_interval,
              current_subscription_status,
              organization.billable_card_on_file?,
              new_subscription_plan_id,
              new_subscription_amount,
              trial_ends_at_should_be_fixed,
              action
             ]
    end

    csv.close
    puts "Logged results of #{mode} to #{file}"
  end
end