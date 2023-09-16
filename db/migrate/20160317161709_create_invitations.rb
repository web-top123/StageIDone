class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.integer :organization_id
      t.integer :team_id
      t.text :email_address
      t.text :full_name
      t.text :invitation_code

      t.timestamps null: false
    end

    add_index :invitations, :organization_id
    add_index :invitations, :team_id
    add_index :invitations, :email_address
    add_index :invitations, :invitation_code
  end
end
