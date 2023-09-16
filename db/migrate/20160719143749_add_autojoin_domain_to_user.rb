class AddAutojoinDomainToUser < ActiveRecord::Migration
  def change
    add_column :users, :autojoin_domain, :text
    add_index :users, :autojoin_domain
  end
end
