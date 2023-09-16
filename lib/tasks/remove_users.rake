namespace :remove_users do
  desc 'Remove unscubscribed users after 3 days of registration'
  task :remove_unsubscribed_user => :environment do
    puts "Removing unscubscribed users"
    users = User.joins(:organizations).where(organizations: {stripe_subscription_status: nil})
            .where("users.created_at <= ?", Time.now - 3.days)
    users.each do |user|
      User.transaction do
        DeletedUser.create(user_id: user.id, email_address: user.email_address, full_name: user.full_name, user_created_at: user.created_at)
        user.personal_teams.each(&:destroy)
        user.really_destroy!
      end
    end
    puts "Done"
  end

  desc 'Remove trialing users after 60 days of registration'
  task :remove_trialing_user => :environment do
    puts "Removing trialing users"
    users = User.joins(:organizations).where(organizations: {stripe_subscription_status: "trialing"})
            .where("users.created_at <= ?", Date.today - 60.days)
    users.each do |user|
      User.transaction do
        DeletedUser.create(user_id: user.id, email_address: user.email_address, full_name: user.full_name, user_created_at: user.created_at, cc_entry: 1)
        user.personal_teams.each(&:destroy)
        user.really_destroy!
      end
    end
    puts "Done"
  end

  desc 'Remove users whose organizations are empty'
  task :remove_empty_organization_user => :environment do
    puts "Removing users whose organizations are empty"
    users = User.all
    users.each do |user|
      User.transaction do
        if !user.organization_memberships.present?
          DeletedUser.create(user_id: user.id, email_address: user.email_address, full_name: user.full_name, user_created_at: user.created_at)
          user.personal_teams.each(&:destroy)
          user.really_destroy!
        end
      end
    end
    puts "Done"
  end

  desc 'Remove users who are never logged in'
  task :remove_never_loggedin_users => :environment do
    puts "Removing never logged in users"
    users = User.where(last_seen_at: nil).where("created_at <= ?", Time.now - 3.days)
    users.each do |user|
      User.transaction do
        user.personal_teams.each(&:destroy)
        user.really_destroy!
      end
    end
    puts "Done"
  end

  desc 'Send email notification before removing users who are not having any active organization from last 60 Days'
  task :send_past_due_notification => :environment do
    puts "Sending email before Removing past due organizations data"
    past_due_organizations = Organization.all.where(stripe_subscription_status: 'past_due')
    past_due_organizations.each do |organization|
      begin
        stripe_customer = Stripe::Customer.retrieve(organization.stripe_customer_token)
        stripe_subscriptions = stripe_customer.subscriptions&.data
        stripe_subscription = stripe_subscriptions&.first
        if stripe_subscription.blank? || ((%w[active trialing]).exclude?(stripe_subscription&.status) &&
          stripe_subscription.current_period_end < (Time.now - 2.months).to_i)
          PastDueOrgDeleteMailer.remove_organization(stripe_customer.email, organization)
        end
      rescue Stripe::StripeError => e
        puts "Organizations #{organization.id}, Error: #{e}"
        Raven.capture_message "Org##{organization.id}: got some error from stripe", extra: { errors: e }
      rescue StandardError => e
        puts "Organizations #{organization.id}, Error: #{e}"
        Raven.capture_message "Org##{organization.id}: got Standard Error", extra: { errors: e }
      end
    end
  end

  desc 'Remove users who are not associated with any active organization from last 60 Days'
  task :remove_past_due_organization_user => :environment do
    puts "Removing past due organizations data"
    past_due_organizations = Organization.all.where(stripe_subscription_status: 'past_due')
    past_due_organizations.each do |organization|
      begin
        stripe_customer = Stripe::Customer.retrieve(organization.stripe_customer_token)
        stripe_subscriptions = stripe_customer.subscriptions&.data
        stripe_subscription = stripe_subscriptions&.first
        if stripe_subscription.blank? || ((%w[active trialing]).exclude?(stripe_subscription&.status) &&
          stripe_subscription.current_period_end < ((Time.now - 6.days) - 2.months).to_i)
          users = organization.users
          organization.destroy!
          puts "Organization Destroyed : #{organization.id}"
          users.each do |user|
            if user.active_organization_memberships.blank?
              DeletedUser.create(user_id: user.id,
                                 email_address: user.email_address,
                                 full_name: user.full_name,
                                 user_created_at: user.created_at)
              user.personal_teams.each(&:destroy!)
              puts "User Destroyed : #{user.id}"
              user.really_destroy!
              Stripe::Customer.delete(stripe_customer.id)
            end
          end
        else
          puts "Organizations #{organization.id} have active subscription"
        end
      rescue Stripe::StripeError => e
        puts "Organizations #{organization.id}, Error: #{e}"
        Raven.capture_message "Org##{organization.id}: got some error from stripe", extra: { errors: e }
      rescue StandardError => e
        puts "Organizations #{organization.id}, Error: #{e}"
        Raven.capture_message "Org##{organization.id}: got Standard Error", extra: { errors: e }
      end
    end
  end
end
