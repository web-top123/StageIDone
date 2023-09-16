class DigestEmailWorker
  include Sidekiq::Worker

  # The default sidekiq retry policy is exponential (to the 4th power) backoff
  # and retrying up to 25 times. This does however mean that an email can be
  # delayed up to 21 days, which is a bit gratuitous. We want to retry a couple
  # of times in short order and then wait up to a few hours at most.
  # The formula is (count ** 4) + 15 + (rand(30) * (count + 1))
  # So the final retry (count = 5) should be around 10 minutes after the first try
  # This parameter as well as the formula can be tweaked if we need to.
  sidekiq_options :retry => 6

  sidekiq_retries_exhausted do |msg|
    Rails.logger.error "------Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}------"
    team_membership = TeamMembership.find(msg['args'][0])
    team_membership.update_attribute(:digest_status, 'error')
  end

  def perform(team_membership_id)    
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
  end
end