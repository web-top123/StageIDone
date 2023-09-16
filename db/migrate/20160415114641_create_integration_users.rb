class CreateIntegrationUsers < ActiveRecord::Migration
  def change
    create_table :integration_users do |t|
      t.references :user, index: true, foreign_key: true
      t.string     :integration_type
      t.string     :oauth_uid
      t.string     :oauth_email
      t.string     :oauth_access_token
      t.boolean    :oauth_access_token_expires
      t.datetime   :oauth_access_token_expires_at
      t.string     :oauth_refresh_token
      t.text       :meta_data

      t.timestamps null: false
    end
  end
end
