class AddVisibilityToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :visibility, :string, default: 'public'
    add_index :teams, :visibility
  end
end
