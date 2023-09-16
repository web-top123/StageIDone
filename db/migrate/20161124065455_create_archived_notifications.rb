class CreateArchivedNotifications < ActiveRecord::Migration
  def change
    create_table :archived_notifications do |t|
      t.string :for_notificable, null: false
      t.integer :counter, null: false, default: 0
      t.timestamps null: false
    end
    add_reference :archived_notifications, :entry, null: false
    add_reference :archived_notifications, :user, null: false

    add_index :archived_notifications, [:for_notificable, :entry_id , :user_id], unique: true, name: 'archived_notifications_uniq'
  end
end
