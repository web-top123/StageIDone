class AddRemovedAtToOrganizationMemberships < ActiveRecord::Migration
  def change
    add_column :organization_memberships, :removed_at, :datetime
    add_index  :organization_memberships, :removed_at
  end
end
