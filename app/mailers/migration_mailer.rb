class MigrationMailer < ApplicationMailer
  def migration_complete(email, success)
    @success = success
    subject = if @success
      'Upgrade complete'
    else
      'Upgrade delayed'
    end

    mail to: email, subject: subject, from: "I Done This <support@idonethis.com>"
  end
end
