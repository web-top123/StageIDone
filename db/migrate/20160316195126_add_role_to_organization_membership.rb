class AddRoleToOrganizationMembership < ActiveRecord::Migration
  def change
    add_column :organization_memberships, :role, :string, default: 'member'
    add_index :organization_memberships, :role
  end
end
