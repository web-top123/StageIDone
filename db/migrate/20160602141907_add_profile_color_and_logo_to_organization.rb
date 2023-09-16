class AddProfileColorAndLogoToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :logo, :string
    add_column :organizations, :profile_color, :string
    Organization.all.each(&:save)
  end
end