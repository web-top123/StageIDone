class AddPersonalTeamToUser < ActiveRecord::Migration
  def change
    add_column :users, :personal_team_id, :integer, unique: true
    add_index :users, :personal_team_id, unique: true

    User.all.each(&:save)
  end
end
