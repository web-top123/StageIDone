class AddUserEntriesCounterCache < ActiveRecord::Migration
  def change
    add_column :users, :entries_count, :integer, default: 0, null: false
    User.find_each do |u|
      User.reset_counters(u.id, :entries)
    end
  end
end
