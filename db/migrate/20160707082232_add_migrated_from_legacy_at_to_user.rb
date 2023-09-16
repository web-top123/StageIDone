class AddMigratedFromLegacyAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :migrated_from_legacy_at, :datetime
    add_index :users, :migrated_from_legacy_at

    if User.first.present?
      User.where('created_at < ?', User.first.created_at).each do |user|
        user.update_column(:migrated_from_legacy_at, user.updated_at)
      end
    end
  end
end
