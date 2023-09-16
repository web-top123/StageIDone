# Preview all emails at http://localhost:3000/rails/mailers/digest_mailer
class DigestMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/digest_mailer/daily_digest_for_team
  def daily_digest_for_user
    DigestMailer.daily_digest_for_user(User.all.last)
  end
end
