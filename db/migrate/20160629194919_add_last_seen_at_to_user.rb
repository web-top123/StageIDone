class AddLastSeenAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_seen_at, :datetime
    add_index :users, :last_seen_at

    User.all.each { |u| u.update_column(:last_seen_at, u.entries.maximum(:updated_at) || Time.zone.now) }
  end
end