class AddProfileColorToUser < ActiveRecord::Migration
  def change
    add_column :users, :profile_color, :string
    add_column :users, :deleted_at, :datetime
    User.all.each(&:save)
  end
end
