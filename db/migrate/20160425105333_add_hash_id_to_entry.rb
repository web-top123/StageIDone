class AddHashIdToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :hash_id, :string, unique: true
    add_index :entries, :hash_id, unique: true

    Entry.all.each(&:save)
  end
end
