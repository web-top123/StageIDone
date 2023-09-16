namespace :team_memberships do
  desc 'Mark TeamMembership#status as inactive if user has not logged entries for a week'
  task :mark_inactive => :environment do
    # Consider only those that have not been frozen
    TeamMembership.with_inactive_entries.not_both_email_days_frozen?.find_each do |team_membership|
      if team_membership.is_email_send_active == "false"
        team_membership.throttle_email_days
      end
      unless team_membership.save
        Raven.capture_message "TM##{team_membership.id}: Could not save.", 
          extra: { errors: team_membership.errors }
      end
    end
  end
end
