class AddOccurredOnToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :occurred_on, :date
    add_index :entries, :occurred_on

    Entry.all.each do |entry|
      entry.update_attribute(:occurred_on, entry.created_at.to_date)
    end
  end
end
