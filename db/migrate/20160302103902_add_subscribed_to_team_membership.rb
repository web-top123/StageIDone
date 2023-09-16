class AddSubscribedToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :subscribed, :boolean, default: false
  end
end
