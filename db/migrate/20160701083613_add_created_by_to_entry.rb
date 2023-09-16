class AddCreatedByToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :created_by, :string
  end
end
