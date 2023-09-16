class AddVerifiedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :verified_at, :datetime, default: nil
    add_column :users, :verification_token, :string, default: nil
    add_column :users, :verification_token_expires_at, :datetime, default: nil

    add_index :users, :verification_token
    add_index :users, :verified_at
  end
end