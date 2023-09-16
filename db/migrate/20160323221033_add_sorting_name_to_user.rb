class AddSortingNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :sorting_name, :text
    add_index :users, :sorting_name

    User.all.each(&:save)
  end
end
