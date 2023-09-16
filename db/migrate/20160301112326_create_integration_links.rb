class CreateIntegrationLinks < ActiveRecord::Migration
  def change
    create_table :integration_links do |t|
      t.integer :user_id
      t.integer :team_id
      t.string :integration_user_id
      t.string :integration_type
      t.text :integration_meta_data

      t.timestamps null: false
    end
  end
end
