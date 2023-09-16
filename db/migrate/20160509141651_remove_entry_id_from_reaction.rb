class RemoveEntryIdFromReaction < ActiveRecord::Migration
  def up
    remove_column :reactions, :entry_id
  end

  def down
    add_column :reactions, :entry_id, :integer
  end
end
