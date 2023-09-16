class AddReactableToReaction < ActiveRecord::Migration
  def up
    add_column :reactions, :reactable_id, :integer
    add_column :reactions, :reactable_type, :string
    add_index :reactions, [:reactable_id, :reactable_type]
  end

  def down
    remove_column :reactions, :reactable_id, :integer
    remove_column :reactions, :reactable_type, :string
    remove_index :reactions, [:reactable_id, :reactable_type]
  end
end
