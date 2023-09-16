class TeamMembershipsController < ApplicationController
  before_action :require_login
  before_action :load_team
  before_action :load_team_membership, only: [:update, :notifications, :notifications_save, :unsubscribe_comments_notification,
                                              :unsubscribe_mentions_notification, :unsubscribe_digests, :unsubscribe_reminders,
                                              :unthrottle_emails,:unsubscribe_assign_task_reminders]

  layout 'modal', only: [:new, :create]

  def index
    @team_memberships = @team.team_memberships.active.alphabetically
    @invitations = @team.organization.invitations.where("? = ANY (team_ids)", @team.id).unredeemed.undeclined.antichronologically

    authorize @team, :settings?
  end

  def new
    @team_membership = TeamMembership.new(team: @team)
    @invitation = Invitation.new(organization: @team.organization, team_ids: [@team.id])

    authorize @team_membership
  end

  def create
    organization = @team.organization

    invitations = []
    team_memberships = []

    # TODO too complex!
    team_memberships_params[:email_addresses].split(',').uniq.map(&:strip).each do |email_address|
      email_address.downcase!
      existing_user = organization.active_users.find_by(email_address: email_address)
      if existing_user.present?
        team_memberships << TeamMembership.find_or_initialize_by(team_id: @team.id, user_id: existing_user.id)
      else
        invitations << Invitation.new(organization: organization, sender: current_user, email_address: email_address, team_ids: [@team.id])
      end
    end

    authorize @team, :settings?

    team_memberships.each(&:join!)
    invitations.each(&:save)

    redirect_to [@team, :team_memberships]
  end

  def update
    authorize @team_membership

    @team_membership.update_attributes(team_membership_params)
    render partial: 'form', locals: { team_membership: @team_membership }
  end

  def notifications
    authorize @team_membership
    render partial: 'notifications', locals: { team_membership: @team_membership }
  end

  def notifications_save
    authorize @team_membership

    @team_membership.update_attributes(notifications_params)
    render partial: 'notifications', locals: { team_membership: @team_membership }
  end

  def unsubscribe_comments_notification
    authorize @team, :update?
    @team_membership.unsubscribe_comments_notification

    redirect_to [:settings, @team]
  end

  def unsubscribe_mentions_notification
    authorize @team, :update?
    @team_membership.unsubscribe_mentions_notification

    redirect_to [:settings, @team]
  end

  def unsubscribe_digests
    authorize @team, :update?
    @team_membership.unsubscribe_digests!

    redirect_to [:settings, @team]
  end

  def unsubscribe_reminders
    authorize @team, :update?
    @team_membership.unsubscribe_reminders!

    redirect_to [:settings, @team]
  end

  def unthrottle_emails
    authorize @team, :update?
    @team_membership.unthrottle_email_days

    redirect_to [:settings, @team]
  end

  def unsubscribe_assign_task_reminders
    authorize @team, :update?
    @team_membership.unsubscribe_assign_task_reminders!

    redirect_to [:settings, @team]
  end

  def destroy
    if params[:key] == "delete"
      team_membership = TeamMembership.find_by(team: @team, id: params[:id])
      authorize team_membership
      team_membership.user.entries.destroy_all
    elsif  params[:key] == "transfer"
      team_membership = TeamMembership.find_by(team: @team, id: params[:id])
      authorize team_membership
      user_entries = team_membership.user.entries
      if params[:user_id]
        user_entries.each do |entry|
          entry.user_id = params[:user_id]
          entry.save
        end
      end
    end
    team_membership.remove!
    # redirect_to root_path
    redirect_to [@team, :team_memberships], notice: "#{team_membership.user.full_name_or_something_else_identifying} was removed"
    # team_membership = TeamMembership.find_by(team: @team, id: params[:id])
    # authorize team_membership
    # team_membership.remove!
    # redirect_to [@team, :team_memberships], notice: "#{team_membership.user.full_name_or_something_else_identifying} was removed"
  end

  private

  def load_team_membership
    @team_membership = current_user.team_memberships.find(params[:id])
  rescue
    redirect_to @team, notice: "No membership found"
  end

  def load_team
    @team = Team.find_by!(hash_id: params[:team_id])
  rescue
    redirect_to root_url, notice: 'This team no longer exists'
  end

  def notifications_params
    params.require(:team_membership).permit(subscribed_notifications: [])
  end

  def team_membership_params
    params.require(:team_membership).permit(:reminder_sunday,
                                            :reminder_monday,
                                            :reminder_tuesday,
                                            :reminder_wednesday,
                                            :reminder_thursday,
                                            :reminder_friday,
                                            :reminder_saturday,
                                            :digest_sunday,
                                            :digest_monday,
                                            :digest_tuesday,
                                            :digest_wednesday,
                                            :digest_thursday,
                                            :digest_friday,
                                            :digest_saturday,
                                            :email_digest_seconds_since_midnight,
                                            :email_reminder_seconds_since_midnight,
                                            :assign_task_reminder_status,
                                            :is_email_send_active)
  end

  def team_memberships_params
    params.require(:team_memberships).permit(:email_addresses)
  end
end
