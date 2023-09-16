class AddTeamIdsToInvitation < ActiveRecord::Migration
  def change
    remove_column :invitations, :team_id
    add_column :invitations, :team_ids, :integer, array: true, default: []
  end
end
