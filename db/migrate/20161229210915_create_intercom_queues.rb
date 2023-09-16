class CreateIntercomQueues < ActiveRecord::Migration
  def change
    create_table :intercom_queues do |t|
      t.references :user, index: { unique: true }, foreign_key: true
      t.datetime :processed_at
      t.timestamps null: false
    end
  end
end
