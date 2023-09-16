class AddStatusToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :status, :string
    add_index :entries, :status

    Entry.update_all(status: 'done')
  end
end
