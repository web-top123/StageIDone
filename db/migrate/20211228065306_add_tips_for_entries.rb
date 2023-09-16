class AddTipsForEntries < ActiveRecord::Migration
  def change
    add_column :entries, :tip, :boolean, after: :status, default: false
  end
end
