class AddInvoicePlanToAppSettings < ActiveRecord::Migration
  def change
    add_column :app_settings, :invoice_monthly_plan_id, :string
    add_column :app_settings, :invoice_yearly_plan_id,  :string
    add_column :app_settings, :invoice_monthly_plan_price_in_cents, :integer, default: 0
    add_column :app_settings, :invoice_yearly_plan_price_in_cents, :integer, default: 0
  end
end
