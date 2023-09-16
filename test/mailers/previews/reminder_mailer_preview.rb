# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/reminder_mailer/daily_reminder
  def daily_reminder
    ReminderMailer.daily_reminder
  end

end
