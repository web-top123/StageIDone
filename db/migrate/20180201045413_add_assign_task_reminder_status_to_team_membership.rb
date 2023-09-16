class AddAssignTaskReminderStatusToTeamMembership < ActiveRecord::Migration
  def change
    add_column :team_memberships, :assign_task_reminder_status, :boolean , default: true, null: false
  end
end
