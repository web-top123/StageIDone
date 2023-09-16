class AddDefaultTeamIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :default_team_id, :integer
  end
end
