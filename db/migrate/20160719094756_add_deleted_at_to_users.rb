class AddDeletedAtToUsers < ActiveRecord::Migration
  def change 
    # Needed to add earlier because model depends on deleted_at existing
    # for an earlier migration. See 20160315214946_add_profile_color_to_user.rb
    unless column_exists? :users, :deleted_at
      add_column :users, :deleted_at, :datetime
    end
    add_index :users, :deleted_at
  end
end
