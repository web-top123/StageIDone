class AddPlanLevelToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :plan_level, :text
    add_column :organizations, :plan_interval, :text

    add_index :organizations, :plan_level
    add_index :organizations, :plan_interval
  end
end
