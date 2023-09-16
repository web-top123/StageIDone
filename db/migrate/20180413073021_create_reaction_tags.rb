class CreateReactionTags < ActiveRecord::Migration
  def change
    create_table :reaction_tags do |t|
      t.integer :reaction_id
      t.integer :tag_id

      t.timestamps null: false
    end
  end
end
