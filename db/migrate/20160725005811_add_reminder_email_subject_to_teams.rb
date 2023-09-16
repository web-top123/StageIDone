class AddReminderEmailSubjectToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :reminder_email_subject, :string, default: "What'd you get done today?"
  end
end
