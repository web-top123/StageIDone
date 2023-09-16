class CreateAlternateEmails < ActiveRecord::Migration
  def change
    create_table :alternate_emails do |t|
      t.references :user, index: true, foreign_key: true
      t.string :email_address, null: false
      t.string :verification_code
      t.datetime :verified_at
      t.timestamps null: false
    end
    add_index :alternate_emails, :email_address, unique: true
    add_index :alternate_emails, :verification_code, unique: true
  end
end
