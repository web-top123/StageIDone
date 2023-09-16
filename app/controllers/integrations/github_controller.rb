class Integrations::GithubController < ApplicationController
  before_action :require_login, except: [:hook]
  skip_after_action :verify_authorized
  protect_from_forgery except: [:hook]
  layout 'modal'

  def oauth_callback
    # TODO: Put in a way to remove this again
    link = IntegrationUser.new_from_github_oauth(
      current_user,
      request.env['omniauth.auth'])

    unless link.save
      flash[:alert] = 'Something went wrong trying to link your account. Please try again later or contact support.'
    end

    redirect_to integrations_github_link_path
  end

  def new_link
    initialize_github_info
  end

  def create_link
    Rails.logger.info "============================create_link===================================="
    integration_user = IntegrationUser.find(link_params[:integration_user_id])
    team = Team.find_by_id(link_params[:team_id])

    render_error('A team is required') and return if team.nil?

    if integration_user.user == current_user && team.active_users.include?(current_user)
      Rails.logger.info "====================if========create_link===================================="
      ActiveRecord::Base.transaction do
        link = IntegrationLink.new(team: team, integration_user: integration_user, integration_type: 'github')
        org = github_params['org']
        repo = github_params['repo']
        webhook_id = Github.set_up_webhook(integration_user, link.token, org, repo)
        link.meta_data = {
          github: {
            org: org,
            repo: repo,
            hook_id: webhook_id,
            commits: github_params['commits'].present?,
            prs: github_params['prs'].present?
          }
        }.to_json
        Rails.logger.info "=========IntegrationLink===========#{link.inspect}===================================="
        if link.save
          redirect_to settings_user_path, notice: 'Integration set up successfully'
        else
          render_error('Failed to set up integration, please try again later or contact support.') and return
        end
      end
    else
      render_error('You do not have permission to set up this integration.') and return
    end
  rescue Octokit::InvalidRepository
    render_error('The repository you selected was invalid.') and return
  rescue Octokit::NotFound
    render_error('You do not have permission to set up this integration.') and return
  end

  def destroy_link
    link = IntegrationLink.find(params[:integration_link_id])
    if link.integration_user.user == current_user
      Github.remove_webhook(link.integration_user, link)
      link.destroy
    end
    redirect_to :back
  end


  def hook
    Rails.logger.info "=============================calling====github===webhook=================="
    link = IntegrationLink.find_by(token: params[:token])
    render nothing: true, status: 200 and return if link.nil?
    case request.headers['X-Github-Event']
    when 'push'
      render nothing: true, status: 200 and return unless link.meta_data.fetch('github', {}).fetch('commits', nil) && params['commits']
      params['commits'].each do |commit|
        if commit['distinct'] && commit['author']['username'] == link.integration_user.meta_data['nickname']
          entry = Entry.create(
            user: link.integration_user.user,
            team: link.team,
            body: commit['message'],
            status: 'done',
            occurred_on: Time.parse(commit['timestamp']),
            created_by: 'github'
          )
          Rails.logger.info "=============================Creating entry from commit, entry id: #{entry.id}"
        end
      end
    when 'pull_request'
      render nothing: true, status: 200 and return unless link.meta_data.fetch('github', {}).fetch('prs', nil)
      # This is a special case becuase it is literally impossible to set the action parameter
      # in a rails test, fucking hate rails so fucking goddamn much
      is_closed = request.request_parameters['action'] == 'closed' || params['ghaction'] == 'closed'
      is_merged = params['pull_request']['merged'] == true
      is_authored = link.integration_user.oauth_uid == params['pull_request']['user']['id'].to_s
      if is_closed && is_merged && is_authored
        entry = Entry.create(
          user: link.integration_user.user,
          team: link.team,
          body: params['pull_request']['title'],
          status: 'done',
          occurred_on: Time.parse(params['pull_request']['closed_at']),
          created_by: 'github'
        )
        Rails.logger.info '===========================Creating entry from pull request, entry id: #{entry.id}'
      end
    else
      Rails.logger.info "Not acting on Github event #{request.headers['X-Github-Event']}"
    end
    render nothing: true, status: 200
  end

  private

  def link_params
    params.require(:integration_link).permit(
      :integration_user_id,
      :team_id)
  end

  def github_params
    params.require(:github).permit(
      :org,
      :repo,
      :commits,
      :prs
    )
  end

  def initialize_github_info
    @github_user = IntegrationUser.find_by(user: current_user, integration_type: 'github')
    redirect_to '/auth/github' and return if @github_user.nil?
    @repo_data = Github.repo_data(@github_user) || {}
  end

  def render_error(message)
    flash[:alert] = message
    initialize_github_info
    render :new_link
  end

end
