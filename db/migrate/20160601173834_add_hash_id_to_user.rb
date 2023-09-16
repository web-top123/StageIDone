class AddHashIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :hash_id, :string, unique: true
    add_index :users, :hash_id, unique: true

    User.all.each(&:save)
  end
end
