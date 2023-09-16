class UserMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @user.generate_reset_password_token!

    mail to: @user.email_address, subject: "Reset your password", from: "I Done This <support@idonethis.com>"
  end

  def verify_user(user)
    @user = user
    @user.generate_verification_token!

    mail to: @user.email_address, subject: "Verify your account", from: "I Done This <support@idonethis.com>"
  end

  def verify_alternate_email(alternate_email_address)
    @user = alternate_email_address.user
    @alternate_email_address = alternate_email_address

    mail to: @alternate_email_address.email_address, subject: "Verify your alternate email address", from: "I Done This <support@idonethis.com>"
  end

  def unsuccessful_email_entry(sender, recipient, entry)
    @sender = sender
    @recipient = recipient
    @entry = entry
    mail to: @sender, subject: "Email entry to #{@recipient} failed", from: "I Done This <support@idonethis.com>", bcc: 'support@idonethis.com'
  end
end
