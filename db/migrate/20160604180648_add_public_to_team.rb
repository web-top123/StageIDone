class AddPublicToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :public, :boolean, default: true
    add_index :teams, :public
    remove_column :teams, :visibility
  end
end
