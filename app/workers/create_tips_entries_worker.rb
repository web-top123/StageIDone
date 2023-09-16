class CreateTipsEntriesWorker
  include Sidekiq::Worker
  def perform(redirection_url, current_user_id, time_zone, last_team_id, last_team_hash_id, cookies_entry_titles)
    entry_titles = ["#onboarding Tip 1 - Use # and @ to tag people & topics",
                    "#onboarding Tip 2 - Set a task to be a Goal, Completed, Blocker",
                    "#onboarding Tip 3 - Adjust email digest frequency in “Team Settings” #{redirection_url + last_team_hash_id}/settings",
                    "#onboarding Tip 4 - Invite team to collaborate in “Members” #{redirection_url + last_team_hash_id}/memberships"
    ]
    entry_titles << cookies_entry_titles if cookies_entry_titles.present?
    entry_array = []
    entry_titles.each do |title|
      entry_array << { body: title,
                       status: 'goal',
                       occurred_on: Time.now.in_time_zone(time_zone).to_date,
                       team_id: last_team_id,
                       user_id: current_user_id,
                       tip: true,
                       created_by: 'app' }
    end
    Entry.create! entry_array
  end
end
