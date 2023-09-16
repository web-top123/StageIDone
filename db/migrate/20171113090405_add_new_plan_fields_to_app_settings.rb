class AddNewPlanFieldsToAppSettings < ActiveRecord::Migration
  def change
  	add_column :app_settings, :basic_monthly_plan_id, :string
    add_column :app_settings, :basic_yearly_plan_id, :string
  	add_column :app_settings, :basic_monthly_plan_price_in_cents, :integer, default: 500
    add_column :app_settings, :basic_yearly_plan_price_in_cents, :integer, default: 400
  end
end
