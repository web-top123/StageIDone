class AddSortingForEntries < ActiveRecord::Migration
  def change
    add_column :entries, :sort, :integer, after: :status
  end
end
