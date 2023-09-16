class AddAutojoinDomainToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :autojoin_domain, :text
    add_index :organizations, :autojoin_domain, unique: true
  end
end
