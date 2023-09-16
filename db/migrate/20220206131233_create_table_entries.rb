class CreateTableEntries < ActiveRecord::Migration
  def change
    create_table :backup_entries, id: false do |t|
      t.integer :id, :auto_increment => false, primary_key: true, index: true
      t.text :body
      t.integer :user_id, index: true
      t.date :occurred_on, index: true
      t.integer :team_id, index: true
      t.string :status, index: true
      t.string :hash_id, index: true
      t.integer :completed_entry_id, index: true
      t.date :completed_on, index: true
      t.datetime :archived_at, index: true
      t.string :created_by, index: true
      t.integer :sort
      t.boolean :tip, default: false

      t.timestamps
    end
  end
end
