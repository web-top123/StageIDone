class DeleteSubscribedFromTeamMemberships < ActiveRecord::Migration
  def change
    remove_column :team_memberships, :subscribed, :boolean, default: false
  end
end
