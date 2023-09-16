class Integrations::SlackController < ApplicationController
  before_action :require_login, except: [:hook]
  skip_after_action :verify_authorized
  protect_from_forgery except: [:hook]
  layout 'modal'

  def oauth_callback
    # TODO: Put in a way to remove this again
    begin
      integration_user = IntegrationUser.new_from_slack_oauth(
        current_user,
        request.env['omniauth.auth'])

      unless integration_user.save
        flash[:alert] = 'Something went wrong trying to link your Slack account. Please try again later or contact support.'
      end
    rescue ActiveRecord::RecordNotUnique => e
        flash[:alert] = e.message
    end

    redirect_to integrations_slack_link_path
  end

  def new_link
    initialize_slack_info
    case(Rails.env)
    when 'development'
      @slack_slash_command = '/local_done'
    when 'staging'
      @slack_slash_command = '/maybe_done'
    when 'production'
      @slack_slash_command = '/done'
    end
  rescue Slack::Web::Api::Error => e
    if e.message == 'token_revoked'
      IntegrationUser.find_by(user: current_user, integration_type: 'slack').destroy
      redirect_to '/auth/slack'
    end
  end

  def create_link
    integration_user = IntegrationUser.find(link_params[:integration_user_id])
    team = Team.find_by_id(link_params[:team_id])

    render_error('A team is required') and return if team.nil?

    if integration_user.user == current_user && team.active_users.include?(current_user)
      if link_params[:integration_type] == 'slack-poster'
        link = IntegrationLink.new(team: team, integration_user: integration_user,
                                   integration_type: link_params[:integration_type],
                                   meta_data: {slack_channel: params[:slack_channel]}.to_json)
        redirect = settings_team_path(team)
      else
        link = IntegrationLink.new(team: team, integration_user: integration_user,
                                   integration_type: link_params[:integration_type])
        redirect = settings_user_path
      end
      if link.save
        flash[:notice] = 'Integration set up successfully'
        redirect_to redirect
      elsif link.invalid?
        render_error(link.errors.full_messages.to_sentence) and return
      else
        render_error('Failed to set up integration, please try again later or contact support.') and return
      end
    else
      render_error('You do not have permission to set up this integration.') and return
    end
  end

  def destroy_link
    link = IntegrationLink.find(params[:integration_link_id])
    if link.integration_user.user == current_user
      link.destroy
    end
    redirect_to :back
  end

  def hook
    render nothing: true, status: 401 and return unless params[:token] == ENV['SLACK_APP_VERIFICATION_TOKEN']
    iuser = IntegrationUser.find_by(oauth_uid: slack_params[:user_id])
    links = IntegrationLink.where(integration_user: iuser, integration_type: 'slack-incoming')
    if links.any?
      links.each do |link|
        # FIXME: Create dones through a unified way that takes into account goal parsing and time zones
        user = link.integration_user.user
        SlackEntryIncomingWorker.perform_async(user.id, link.team.id, slack_params[:text], Time.current.in_time_zone(user.time_zone).to_date)
      end
      render json: {text: 'Got it!'}
    else
      msg =<<MSG
You haven't activated the slack integration for your user yet.
Go to the integrations page at beta.idonethis.com/integrations to do this.
MSG
      render json: {text: msg}
    end
  end

  private

  def slack_params
    params.permit(:user_id, :text)
  end

  def link_params
    params.require(:integration_link).permit(
      :integration_user_id,
      :team_id,
      :integration_type
    )
  end

  def initialize_slack_info
    @slack_user  = IntegrationUser.find_by(user: current_user, integration_type: 'slack')
    redirect_to '/auth/slack' and return if @slack_user.nil?
    @slack_client = Slack::Web::Client.new(token: @slack_user.oauth_access_token)
    @slack_channels = @slack_client.channels_list(exclude_archived: true).channels.map{|c| c.name}
    @slack_slash_command = IntegrationLink.slack_slash_command
  end

  def render_error(message)
    flash[:alert] = message
    initialize_slack_info
    render :new_link
  end

end
