class AddStripeCustomerTokenToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :stripe_customer_token, :string
  end
end
