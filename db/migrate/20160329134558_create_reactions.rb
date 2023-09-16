class CreateReactions < ActiveRecord::Migration
  def change
    create_table :reactions do |t|
      t.integer :entry_id
      t.integer :user_id
      t.text :body

      t.timestamps null: false
    end

    add_index :reactions, :entry_id
    add_index :reactions, :user_id
  end
end
