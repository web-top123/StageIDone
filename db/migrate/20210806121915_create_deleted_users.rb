class CreateDeletedUsers < ActiveRecord::Migration
  def change
    create_table :deleted_users do |t|
      t.integer :user_id  
      t.string :email_address
      t.text :full_name
      t.datetime :user_created_at
      t.integer :cc_entry, default: 0

      t.timestamps null: false
    end
  end
end
