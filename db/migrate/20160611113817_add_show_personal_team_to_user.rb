class AddShowPersonalTeamToUser < ActiveRecord::Migration
  def change
    add_column :users, :show_personal_team, :boolean, default: true
    add_index :users, :show_personal_team
  end
end
