class AddFrozenReminderDaysAndDigestDaysToTeamMemberships < ActiveRecord::Migration
  def change
    add_column :team_memberships, :frozen_reminder_days, :integer, null: false, default: 0
    add_column :team_memberships, :frozen_digest_days, :integer, null: false, default: 0
  end
end
