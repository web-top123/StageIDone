namespace :send_emails do
  desc 'Send daily digests to users subscribed to users'
  task :digests => :environment do
    TeamMembership.digest_should_be_sent_in(2.minutes.from_now).find_each do |team_membership|
        # Rails.logger.info "----#{team_membership.inspect}--------"

        # Rails.logger.info "Queueing up digest email for TM##{team_membership.id}"
      team_membership.update_attributes(digest_status: 'inqueue')
      team_membership_id = team_membership.id
      # Rails.logger.info "Next sending will be on #{team_membership.next_digest_time}"
      team_membership = TeamMembership.eager_load(:team, :user).find(team_membership_id)
      team = team_membership.team
      user = team_membership.user
  
      if user.present? && team.present? 
        if user.last_seen_at? && user.last_seen_at >= (Time.now - 2.month)
          Rails.logger.info "------Sending digest email for team: #{team.name} and user #{user.email_address}------"
          # if user.created_at >= "2017-12-17" && (team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active")
          #   Rails.logger.info "------------------if-------send---------"
          #   DigestMailer.daily_digest(team_membership).deliver_now
          if user.created_at >= "2008-12-17" && user.deleted_at.nil?
            if team.personal?
              if user.created_at >= "2017-12-17"  
                if user.organizations.present?         
                  statuses = user.organizations.pluck(:stripe_subscription_status)
                  if  statuses.include?("trialing") or statuses.include?("active")
                    Rails.logger.info "------to-send-personal--email---check-status-for-new-users---------"
                    DigestMailer.daily_digest(team_membership).deliver_now
                  end
                end
              else
                Rails.logger.info "------old-users------4------> Send mail 1-----"
                DigestMailer.daily_digest(team_membership).deliver_now
              end
            elsif team.organization.present?
              #Rails.logger.info "------------1------> #{team.organization.inspect}------"
              # if team.organization.stripe_subscription_status != "trialing" && team.organization.stripe_subscription_status != "active"
              if team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active"
                #Rails.logger.info "------------4------> Send mail 1------"
                DigestMailer.daily_digest(team_membership).deliver_now
              else
                #Rails.logger.info "------------2------> #{team.organization.stripe_subscription_status.inspect}------"
                #Rails.logger.info "------Not Sending------"
              end
            else
              #Rails.logger.info "------------5-----> Not Sending------"
            end
          else
            if user.deleted_at.nil?
              if team.personal?
                if user.created_at >= "2017-12-17"  
                  if user.organizations.present?         
                    statuses = user.organizations.pluck(:stripe_subscription_status)
                    if  statuses.include?("trialing") or statuses.include?("active")
                      Rails.logger.info "------to-send-personal--email---check-status-for-new-users------------"
                      DigestMailer.daily_digest(team_membership).deliver_now
                    end
                  end
                else
                  Rails.logger.info "------------4------> Send mail 1------"
                  DigestMailer.daily_digest(team_membership).deliver_now
                end
              elsif team.organization.present?
                if team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active"
                  #Rails.logger.info "-------------6-----> Send mail 2------"
                  DigestMailer.daily_digest(team_membership).deliver_now
                end
              end
            end
          end
        end
      end
      # DigestMailer.daily_digest(team_membership).deliver_now
      team_membership.email_digest_last_sent_at = Time.current
      team_membership.digest_status = nil
      team_membership.save
      # DigestEmailWorker.perform_at(team_membership.next_digest_time, team_membership.id)
    end
  end

  desc 'Send daily reminders to users subscribed to users'
  task :reminders => :environment do
    Rails.logger.info "---reminder---"
    initial_delay = 10.seconds
    TeamMembership.reminder_should_be_sent_in(2.minutes.from_now).find_each do |team_membership|

        # Rails.logger.info "Queueing up reminder email for TM##{team_membership.id}"
      initial_delay += 10.seconds
      team_membership.update_attributes(reminder_status: 'inqueue')
      team_membership_id = team_membership.id
      team_membership = TeamMembership.eager_load(:team, :user).find(team_membership_id)
      team = team_membership.team
      user = team_membership.user

      if user.present? && team.present? 
        if user.last_seen_at? && user.last_seen_at >= (Time.now - 2.month)
          Rails.logger.info "------Sending reminder email for team: #{team.name} and user #{user.email_address}------"
          if user.created_at >= "2008-12-17" && user.deleted_at.nil?
            if team.personal?
              if user.created_at >= "2017-12-17"  
                if user.organizations.present?         
                  statuses = user.organizations.pluck(:stripe_subscription_status)
                  if  statuses.include?("trialing") or statuses.include?("active")
                    Rails.logger.info "------to-send-personal--email---check-status-for-new-users---------"
                    ReminderMailer.daily_reminder(team, user).deliver_now
                  end
                end
              else
                Rails.logger.info "------old-users------4------> Send mail 1-----"
                ReminderMailer.daily_reminder(team, user).deliver_now
              end          
            elsif team.organization.present?
              Rails.logger.info "------------1------> #{team.organization.inspect}------"
              # if team.organization.stripe_subscription_status != "trialing" && team.organization.stripe_subscription_status != "active"
              if team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active"
                Rails.logger.info "------------4------> Send mail 1------"
                ReminderMailer.daily_reminder(team, user).deliver_now
              else
                Rails.logger.info "------------2------> #{team.organization.stripe_subscription_status.inspect}------"
                Rails.logger.info "------Not Sending------"
              end
            else
              Rails.logger.info "------------5-----> Not Sending------"
            end
          else
            if user.deleted_at.nil?
              if team.personal?
                if user.created_at >= "2017-12-17"  
                  if user.organizations.present?         
                    statuses = user.organizations.pluck(:stripe_subscription_status)
                    if  statuses.include?("trialing") or statuses.include?("active")
                      Rails.logger.info "------to-send-personal--email---check-status-for-new-users---------"
                      ReminderMailer.daily_reminder(team, user).deliver_now
                    end
                  end
                else
                  Rails.logger.info "------old-users------4------> Send mail 1-----"
                  ReminderMailer.daily_reminder(team, user).deliver_now
                end  
              elsif team.organization.present?
                if team.organization.stripe_subscription_status == "trialing" || team.organization.stripe_subscription_status == "active"
                  Rails.logger.info "-------------6-----> Send mail 2------"
                  ReminderMailer.daily_reminder(team, user).deliver_now
                end
              end
            end
          end
        end

        # Rails.logger.info "Sending reminder email for team: #{team.name} and user #{user.email_address}"
        # ReminderMailer.daily_reminder(team, user).deliver_now
        
        team_membership.email_reminder_last_sent_at = Time.current
        team_membership.reminder_status = nil
        team_membership.save
      end
      # ReminderEmailWorker.perform_at(team_membership.next_reminder_time, team_membership.id)
      
    end
  end

  desc 'Send subscription renewal reminder email'
  task :subscription_renewal_reminder => :environment do
    Organization.active.each do |organization|
      upcoming_invoice = Stripe::Invoice.upcoming({
                                                    customer: organization.stripe_customer_token
                                                  })
      next unless upcoming_invoice.present?

      invoice_date = Time.at(upcoming_invoice[:created]).to_date
      owner = User.find_by(email_address: upcoming_invoice[:customer_email])
      next unless owner.present?

      if (invoice_date - Time.now.in_time_zone(owner.time_zone).to_date) == 7
        SubscriptionReminderWorker.perform_async(upcoming_invoice, organization, owner)
      end
    end
  end
end
