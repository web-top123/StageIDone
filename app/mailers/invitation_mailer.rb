class InvitationMailer < ApplicationMailer
  def organization_invitation(invitation)
    @invitation = invitation

    mail to: @invitation.email_address, subject: "Invitation to use I Done This", from: "I Done This <invitation@idonethis.com>"
  end

  def invitation_declined(invitation)
    return if invitation.sender.nil?

    @invitation = invitation

    mail to: @invitation.sender.email_address, subject: "I Done This - #{@invitation.email_address} declined invite", from: "I Done This <invitation@idonethis.com>"
  end
end
