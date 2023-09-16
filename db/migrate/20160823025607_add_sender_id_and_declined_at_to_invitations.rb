class AddSenderIdAndDeclinedAtToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :sender_id, :integer
    add_column :invitations, :declined_at, :datetime

    add_index :invitations, :sender_id
    add_index :invitations, :declined_at
  end
end
