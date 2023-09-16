class AddTimestampsCustomizationToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :enable_entry_timestamps, :boolean
  end
end
