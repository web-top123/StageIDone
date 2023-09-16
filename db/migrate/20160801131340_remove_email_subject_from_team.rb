class RemoveEmailSubjectFromTeam < ActiveRecord::Migration
  def up
    default_subject = "What'd you get done today?"
    Team.all.each do |team|
      next if team.reminder_email_subject == default_subject
      team.update_column :prompt_done, team.reminder_email_subject
    end

    remove_column :teams, :reminder_email_subject
  end

  def down
    add_column :teams, :reminder_email_subject, :string, default: "What'd you get done today?"
  end
end
