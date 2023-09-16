class AddHashIdToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :hash_id, :string, unique: true
    add_index :teams, :hash_id, unique: true

    Team.all.each(&:save)
  end
end
