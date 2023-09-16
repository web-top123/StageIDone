class AddOrganizationIdToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :organization_id, :integer
    add_index :teams, :organization_id

    Team.all.each do |team|
      team.organization = team.users.first.organization
      team.save!
    end
  end
end
