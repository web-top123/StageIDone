class CreateAppSettings < ActiveRecord::Migration
  def change
    create_table :app_settings do |t|
      t.string :tiny_monthly_plan_id
      t.string :tiny_yearly_plan_id
      t.string :small_monthly_plan_id
      t.string :small_yearly_plan_id
      t.string :medium_monthly_plan_id
      t.string :medium_yearly_plan_id
      t.string :large_monthly_plan_id
      t.string :large_yearly_plan_id

      t.timestamps null: false
    end
  end
end
