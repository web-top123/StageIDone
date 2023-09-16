class AddBilledManuallyToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :billed_manually, :boolean, default: false
  end
end
