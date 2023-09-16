class RenameEmailFieldsToReminders < ActiveRecord::Migration
  def change
    rename_column :team_memberships, :email_monday,    :reminder_monday
    rename_column :team_memberships, :email_tuesday,   :reminder_tuesday
    rename_column :team_memberships, :email_wednesday, :reminder_wednesday
    rename_column :team_memberships, :email_thursday,  :reminder_thursday
    rename_column :team_memberships, :email_friday,    :reminder_friday
    rename_column :team_memberships, :email_saturday,  :reminder_saturday
    rename_column :team_memberships, :email_sunday,    :reminder_sunday
  end
end
