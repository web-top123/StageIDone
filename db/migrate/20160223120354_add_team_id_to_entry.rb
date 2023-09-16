class AddTeamIdToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :team_id, :integer
    add_index :entries, :team_id
  end
end
