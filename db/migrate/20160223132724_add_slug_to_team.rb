class AddSlugToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :slug, :string
    add_index :teams, :slug

    Team.all.each(&:save)
  end
end
