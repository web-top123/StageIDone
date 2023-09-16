class OrganizationMembershipsController < ApplicationController
  before_action :require_login

  def index
    @organization = Organization.find_by(hash_id: params[:organization_id])
    @organization_memberships = @organization.organization_memberships.active.alphabetically
    @invitations = @organization.invitations.unredeemed.undeclined.antichronologically

    authorize @organization_memberships
  end

  def update
    organization = Organization.find_by(hash_id: params[:organization_id])
    organization_membership = organization.organization_memberships.find(params[:id])

    organization_membership.attributes = organization_membership_params

    # T O D O: Ensure the right person can move members -> admin -> owners
    authorize organization_membership

    # organization_membership.update_attributes(organization_membership_params)
    organization_membership.save
    redirect_to [organization, :organization_memberships], notice: "#{organization_membership.user.full_name_or_something_else_identifying} has been changed to #{organization_membership.role}."
    # render text: ''
  rescue Pundit::NotAuthorizedError
    redirect_to [organization, :organization_memberships], notice: "You cannot change members to #{organization_membership.role}s."
  end

  def destroy
    organization = Organization.find_by(hash_id: params[:organization_id])
    organization_membership = organization.organization_memberships.find(params[:id])

    authorize organization_membership

    organization_membership.remove!

    redirect_to [organization, :organization_memberships], notice: "#{organization_membership.user.full_name_or_something_else_identifying} has been removed."
  end

  private

  def organization_membership_params
    params.require(:organization_membership).permit(:role)
  end
end
