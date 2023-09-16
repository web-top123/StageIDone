class AddEnableExpandableEntriesBox < ActiveRecord::Migration
  def change
    add_column :teams, :enable_expandable_entries_box, :boolean, default: false, null: false
  end
end
