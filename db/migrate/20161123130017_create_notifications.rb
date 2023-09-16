class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :for_notificable, null:false
      t.timestamps null: false
    end
    add_reference :notifications, :entry, null: false
    add_reference :notifications, :user, null: false
  end
end
