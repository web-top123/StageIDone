class CreateHooks < ActiveRecord::Migration
  def change
    create_table :hooks do |t|
      t.references :user, index: true, foreign_key: true
      t.references :team, index: true, foreign_key: true
      t.text :url

      t.timestamps null: false
    end
  end
end
