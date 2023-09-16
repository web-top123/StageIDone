class PastDueOrgDeleteMailer < ApplicationMailer
  def remove_organization(owner_email_address, organization)
    @owner_email_address = owner_email_address
    @organization = organization

    mail to: @owner_email_address, subject: "Account Deactivation / Renewal Emails", from: "I Done This <invitation@idonethis.com>"
  end
end
