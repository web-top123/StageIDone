class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.text :name
      t.string :slug

      t.timestamps null: false
    end

    add_index :organizations, :slug
  end
end
