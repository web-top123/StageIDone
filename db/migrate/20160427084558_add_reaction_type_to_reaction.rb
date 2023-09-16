class AddReactionTypeToReaction < ActiveRecord::Migration
  def change
    add_column :reactions, :reaction_type, :string
    add_index :reactions, :reaction_type

    Reaction.update_all(reaction_type: 'comment')
  end
end
