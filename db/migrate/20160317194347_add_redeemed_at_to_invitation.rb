class AddRedeemedAtToInvitation < ActiveRecord::Migration
  def change
    add_column :invitations, :sent_at, :datetime
    add_column :invitations, :redeemed_at, :datetime
  end
end
