class CreateAdminUsers < ActiveRecord::Migration
  def change
    create_table :admin_users do |t|
      t.string :full_name
      t.string :email_address
      t.datetime :last_login_at

      t.timestamps null: false
    end
  end
end
