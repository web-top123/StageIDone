class AddOnboardedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :onboarded_at, :datetime
    add_index :users, :onboarded_at
  end
end
