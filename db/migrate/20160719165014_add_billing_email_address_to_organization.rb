class AddBillingEmailAddressToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :billing_email_address, :text
  end
end
