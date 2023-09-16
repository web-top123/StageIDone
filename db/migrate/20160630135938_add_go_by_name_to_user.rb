class AddGoByNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :go_by_name, :text
    add_index :users, :go_by_name

    User.all.each do |u|
      next unless u.full_name.present?

      namae = Namae::Name.parse(u.full_name)
      u.update_column(:go_by_name, namae.given)
    end
  end
end
