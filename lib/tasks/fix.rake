namespace :fix do
  desc "Remove trial subscriptions with no billing info"
  task :remove_trial_subscriptions => :environment do
    Organization.find_each do |organization|

      if organization.stripe_customer.present? && organization.stripe_customer.subscriptions.any?
        subscription = organization.stripe_customer.subscriptions.first
        # if on trial/past_due subscription and no cards on file
        if (subscription.status == 'trialing' || subscription.status == 'past_due') && organization.stripe_customer.sources.empty?
          subscription.delete
          organization.update_columns(plan_level: nil, plan_interval: nil, stripe_subscription_status: nil)
          puts "Deleted subscription for Organization #{organization.hash_id}"
        else
          organization.update_column(:stripe_subscription_status, subscription.status)
        end
      end
    end
  end

  desc "Remove orphaned team invitations"
  task :orphaned_team_invites => :environment do
    Invitation.where("array_length(team_ids, 1) > 0").find_each do |invitation|
      invitation.team_ids.each do |team_id|
        invitation.team_ids.delete(team_id) unless Team.exists?(team_id)
      end

      # if any team ids were removed
      if invitation.team_ids_changed?
        # and the invite was only for one team
        if invitation.team_ids.empty?
          invitation.destroy
        # else save invite with remaining team ids
        else
          invitation.save
        end
      end
    end
  end
end
