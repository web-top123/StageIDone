class AddStripeSubscriptionStatusToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :stripe_subscription_status, :string
  end
end
