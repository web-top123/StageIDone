class RefactorTeamMembershipStatusToRemovedAt < ActiveRecord::Migration
  def up
    add_column :team_memberships, :removed_at, :datetime
    add_index :team_memberships, :removed_at
    TeamMembership.where(status: 'inactive').update_all('removed_at = updated_at')
    remove_column :team_memberships, :status
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
