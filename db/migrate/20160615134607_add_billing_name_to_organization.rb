class AddBillingNameToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :billing_name, :text
  end
end
