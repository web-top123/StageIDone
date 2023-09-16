class AddDeletedAtToTeamAndOrganizationMemberships < ActiveRecord::Migration
  def change
    add_column :team_memberships, :deleted_at, :datetime
    add_index  :team_memberships, :deleted_at

    add_column :organization_memberships, :deleted_at, :datetime
    add_index  :organization_memberships, :deleted_at
  end
end
