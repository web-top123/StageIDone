class AddMentionableToMention < ActiveRecord::Migration
  def change
    add_reference :mentions, :mentionable, polymorphic: true, index: true
    remove_column :mentions, :entry_id
  end
end
