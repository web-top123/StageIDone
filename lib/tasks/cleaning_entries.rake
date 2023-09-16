namespace :cleaning_entries do
  desc "Move entries of active user to another table"
  task run: :environment do

    User.all.each do |user|
      begin
        organization_memberships = user.organization_memberships
        org_status_count = 0
        organization_memberships.each do |org_member|
          organization = org_member.organization
          if %w[active trialing].include?(organization.stripe_subscription_status)
            org_status_count += 1
            organization_teams = organization.teams
            organization_teams.each do |team|
              team.entries.where(user_id: user.id).each do |entry|
                BackupEntry.create entry.attributes
              end
            end
          end
        end
        if org_status_count > 0
          begin
            personal_teams = user.teams.where(organization_id: nil)
            personal_teams.each do |team|
              team.entries.each do |entry|
                BackupEntry.create entry.attributes
              end
            end
          rescue StandardError => e
            puts "Personal Team Error: #{e}"
            Raven.capture_message "Personal team : got Standard Error", extra: { errors: e }
          end
        end
      rescue StandardError => e
        puts "User #{user.id}, Error: #{e}"
        Raven.capture_message "User #{user.id}: got Standard Error", extra: { errors: e }
      end
    end
  end
end