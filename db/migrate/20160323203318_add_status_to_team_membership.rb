class AddStatusToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :status, :string, default: 'active'
    add_index :team_memberships, :status
  end
end
