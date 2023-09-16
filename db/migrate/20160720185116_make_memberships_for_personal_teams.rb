class MakeMembershipsForPersonalTeams < ActiveRecord::Migration
  def change
    User.all.each do |user|
      next unless user.personal_team_id.present?

      t = Team.find_by(id: user.personal_team_id)
      TeamMembership.create! team: t, user: user
    end
  end
end
