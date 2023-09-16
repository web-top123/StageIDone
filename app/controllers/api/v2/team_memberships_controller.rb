class Api::V2::TeamMembershipsController < Api::V2::BaseController

  # GET
  # http://localhost:3000/api/v2/team_memberships/fetch_team_membership?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&user_id=2&team_id=5
  def fetch_team_membership
    @team = Team.find_by(:id => params[:team_id])
    @team_membership = TeamMembership.where(user_id: params[:user_id],team_id: params[:team_id]).first
    render formats: :json
  end
 
  # GET
  # http://localhost:3000//api/v2/team_memberships/5/notifications_save?team_id=2bc8ab91ac4b&api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af&team_membership[subscribed_notifications][]=comment&team_membership[subscribed_notifications][]=mention&team_membership[subscribed_notifications][]=
  def notifications_save
    # authorize @team_membership
    # @team_membership = TeamMembership.where(user_id: params[:user_id],team_id: params[:team_id]).first
    @team_membership = TeamMembership.find(params[:id])
    @team_membership.update_attributes(notifications_params)
    @team_membership.save!
    render formats: :json
  end

  # POST
  # http://localhost:3000//api/v2/team_memberships?id=7182e15436aa&api_token=57bc1edeca212b6cec0e9e8f8b3748a9b02beaa7&email_addresses=hardik@inuscg.com
  def create
    @team = Team.find_by(:hash_id => params[:id])
    if @team.owner_id == @current_user.id
      @organization = @team.organization
      invitations = []
      team_memberships = []
      # TODO too complex!
      params[:email_addresses].split(',').uniq.map(&:strip).each do |email_address|
        email_address.downcase!
        existing_user = @organization.active_users.find_by(email_address: email_address)
        if existing_user.present?
          team_memberships << TeamMembership.find_or_initialize_by(team_id: @team.id, user_id: existing_user.id)
        else
          invitations << Invitation.new(organization: @organization, sender: @current_user, email_address: email_address, team_ids: [@team.id])
        end
      end
      team_memberships.each(&:join!)
      invitations.each(&:save)
      render json: { success: "done." }, status: 200
    else
      error!('You do not have access to add member in this team.', 401) and return
    end
  end
 
  # DELETE
  # http://localhost:3000//api/v2/team_memberships/18?team_id=161aa47517ef&api_token=7264a1118f8c6cf42354734456a7d8916f6c9650&key=delete
  def destroy
    @team = Team.find_by!(hash_id: params[:team_id])
    if params[:key] == "delete"
      team_membership = TeamMembership.find_by(team: @team, id: params[:id])
      team_membership.user.entries.destroy_all
    elsif  params[:key] == "transfer"
      team_membership = TeamMembership.find_by(team: @team, id: params[:id])
      user_entries = team_membership.user.entries
      if params[:user_id]
        user_entries.each do |entry|
          entry.user_id = params[:user_id]
          entry.save
        end
      end
    end
    team_membership.remove!
    render json: { success: "done." }, status: 200
  end

  # PATCH
  # http://localhost:3000//api/v2/team_memberships/13?api_token=03b7a3930b23152c00d188e8401b4ecbab455ec9&team_membership[assign_task_reminder_status]=true&team_membership[reminder_sunday]=false&team_membership[reminder_monday]=true&team_membership[reminder_tuesday]=true&team_membership[reminder_wednesday]=true&team_membership[reminder_thursday]=true&team_membership[reminder_friday]=true&team_membership[reminder_saturday]=true&team_membership[digest_sunday]=false&team_membership[digest_sunday]=false&team_membership[digest_monday]=false&team_membership[digest_tuesday]=false&team_membership[digest_wednesday]=false&team_membership[digest_thursday]=false&team_membership[digest_friday]=false&team_membership[digest_saturday]=false&team_membership[email_digest_seconds_since_midnight]=30600&team_membership[email_reminder_seconds_since_midnight]=30600
  def update
    # authorize @team_membership
    # @team_membership = TeamMembership.where(user_id: params[:user_id],team_id: params[:team_id]).first
    @team_membership = TeamMembership.find(params[:id])
    @team_membership.update_attributes(team_membership_params)
    render formats: :json
  end
  
  private

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
                                            :assign_task_reminder_status)
  end

  def notifications_params
    params.require(:team_membership).permit(subscribed_notifications: [])
  end
end