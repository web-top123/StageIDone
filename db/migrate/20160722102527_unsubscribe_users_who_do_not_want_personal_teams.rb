class UnsubscribeUsersWhoDoNotWantPersonalTeams < ActiveRecord::Migration
  def change
    User.all.each do |user|
      if !user.show_personal_team
        user.personal_teams.each do |team|
          tm = user.membership_of(team)
          tm.unsubscribe_from_all!
        end
      end
    end
  end
end
