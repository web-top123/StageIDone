class AddArchivedAtToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :archived_at, :datetime
    add_index :entries, :archived_at
  end
end
