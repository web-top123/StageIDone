class AddPlanPricesToAppSettings < ActiveRecord::Migration
  def change
    add_column :app_settings, :tiny_monthly_plan_price_in_cents, :integer, default: 0
    add_column :app_settings, :tiny_yearly_plan_price_in_cents, :integer, default: 0
    add_column :app_settings, :small_monthly_plan_price_in_cents, :integer, default: 12_50
    add_column :app_settings, :small_yearly_plan_price_in_cents, :integer, default: 9_00
    add_column :app_settings, :medium_monthly_plan_price_in_cents, :integer, default: 25_00
    add_column :app_settings, :medium_yearly_plan_price_in_cents, :integer, default: 22_00
    add_column :app_settings, :large_monthly_plan_price_in_cents, :integer, default: 40_00
    add_column :app_settings, :large_yearly_plan_price_in_cents, :integer, default: 35_00
  end
end