class CreateMentions < ActiveRecord::Migration
  def change
    create_table :mentions do |t|
      t.integer :entry_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
