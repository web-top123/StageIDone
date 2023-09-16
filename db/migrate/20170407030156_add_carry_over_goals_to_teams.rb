class AddCarryOverGoalsToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :carry_over_goals, :boolean, default: true, null: false
  end
end
