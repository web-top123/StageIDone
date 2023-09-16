class AddGoalCompletionToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :completed_entry_id, :integer
    add_column :entries, :completed_on, :date

    add_index :entries, :completed_entry_id
    add_index :entries, :completed_on
  end
end
