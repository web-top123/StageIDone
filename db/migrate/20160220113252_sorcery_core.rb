class SorceryCore < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email_address,            :null => false
      t.string :crypted_password
      t.string :salt
      t.text :full_name

      t.timestamps
    end

    add_index :users, :email_address, unique: true
  end
end