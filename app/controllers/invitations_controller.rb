class InvitationsController < ApplicationController
  before_action :require_login

  layout 'modal', only: [:new, :create]

  def new # this should probably be moved into OrganizationMembership controller
    @organization = Organization.find_by(hash_id: params[:organization_id])
    @invitation = Invitation.new(organization: @organization, sender: current_user)

    authorize @invitation
  end

  def create # actually creates multiple invitations, so kind of a non-RESTful misnomer
    org = Organization.find_by(hash_id: params[:organization_id])

    invitations = []

    invitations_params[:email_addresses].split(',').uniq.each do |email_address|
      invitations << Invitation.new(organization: org, sender: current_user, email_address: email_address.strip)
    end

    authorize invitations.last

    invitations.each(&:save)

    redirect_to [org, :organization_memberships]
  end

  def resend
    invitation = Invitation.find_by(invitation_code: params[:id])

    authorize invitation

    invitation.send_invitation!
    render partial: 'invitations/summary', locals: { invitation: invitation }
  end

  def destroy
    invitation = Invitation.find_by(invitation_code: params[:id])

    authorize invitation

    invitation.destroy
    render text: ''
  end

  def accept
    invitation = Invitation.find_by(invitation_code: params[:id])

    authorize invitation

    OrganizationMembership.find_or_initialize_by(role: 'member', organization: invitation.organization, user: current_user).join!

    invitation.teams.each { |t| TeamMembership.find_or_initialize_by(team: t, user: current_user).join! }

    invitation.redeem_invitation!

    redirect_to notifications_url, notice: "Invitation accepted."
  end

  def decline
    invitation = Invitation.find_by(invitation_code: params[:id])

    authorize invitation

    invitation.decline_invitation!

    redirect_to notifications_url, notice: "Invitation declined."
  end

  private

  def invitations_params
    params.require(:invitations).permit(:email_addresses)
  end
end
