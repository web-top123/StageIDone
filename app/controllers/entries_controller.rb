class EntriesController < ApplicationController
  before_action :require_login

  def create
    team = Team.find_by(hash_id: params[:team_id])
    entry = Entry.new(body: params['entry_body'],
                      status: params['entry_status'],
                      occurred_on: params['entry_occurred_on'],
                      team: team,
                      user: current_user,
                      created_by: 'app')
    authorize entry
    if entry.save
      html_content = render_to_string(partial: 'entries/entry_brief',
                                      locals: { entry: entry, entry_user: entry.user, entry_team: team, team_organization: team.organization},
                                      formats: [:html],
                                      layout: false)
      render json: { entry_brief: html_content, sortable_id: entry.sortable_id}
    else
      render partial: 'entries/form', locals: { entry: entry, team: team }, status: 422
    end
  end

  def brief
    entry = Entry.find_by_hash_id(params[:id])
    if entry
      authorize entry
      entry_team = entry.team
      render partial: 'entries/entry_brief', locals: { entry: entry, entry_user: entry.user, entry_team: entry_team, team_organization: entry_team.organization }
    else
      skip_authorization
      head :ok, content_type: "text/html"
    end
  end

  def edit
    entry = Entry.find_by_hash_id(params[:id])
    if entry
      authorize entry
      team = entry.team
      render partial: 'entries/form', locals: { team: team, entry: entry }
    else
      skip_authorization
      head :ok, content_type: "text/html"
    end
  end

  def update
    entry = Entry.find_by_hash_id(params['id'])
    authorize entry
    entry.body = params['entry_body']
    entry.occurred_on = params['entry_occurred_on']
    entry.status = params['entry_status']
    entry.save
    entry_team = entry.team
    render partial: 'entries/entry_brief', locals: { entry: entry, entry_user: entry.user, entry_team: entry_team, team_organization: entry_team.organization }
  end

  def destroy
    entry = Entry.find_by_hash_id(params[:id])
    if entry
      team = entry.team
      authorize entry
      entry.destroy
    else
      skip_authorization
    end
    redirect_to :back
  end

  def assign
    entry = Entry.find_by_hash_id(params[:id])
    authorize entry
    if params[:user_id]
      entry.user_id = params[:user_id]
      entry.save
    end
    @sender_user = current_user
    @receiver_user = User.find(params[:user_id])
    @team = entry.team
    @task = entry
    @team_membership = TeamMembership.where(user_id: @receiver_user.id ,team_id: @team.id).first
    if @team_membership.assign_task_reminder_status == true
      EntryMailer.assigned_task(@sender_user, @receiver_user,@team,@task).deliver_now
    end
    redirect_to root_path
  end

  # TODO: fredrik :(
  def toggle_like
    entry = Entry.find_by_hash_id(params[:id])
    authorize entry
    entry_team = entry.team
    @team_members = entry_team.users
    reaction = Reaction.is_like.where(reactable: entry, user: current_user).first
    if reaction
      reaction.destroy!
    else
      Reaction.create! reactable: entry, reaction_type: 'like', user: current_user
    end
    render partial: 'entries/entry_brief', locals: { entry: entry, entry_user: entry.user, entry_team: entry_team, team_organization: entry_team.organization }
  end

  # TODO: fredrik :(
  def mark_done
    entry = Entry.find_by(hash_id: params[:id])
    authorize entry
    entry.mark_done!(Date.current)
    entry_team = entry.team
    render partial: 'entries/entry_brief', locals: { entry: entry.completed_entry, entry_user: entry.user, entry_team: entry_team, team_organization: entry_team.organization }
  end

  # TODO: fredrik :(
  def archive
    entry = Entry.find_by(hash_id: params[:id])
    authorize entry
    if !entry.completed?
      entry.archived_at = Time.zone.now
      entry.save!
    end
    render text: 'success'
  end

  private

  def entry_params
    params.require(:entry).permit(:body, :occurred_on, :status)
  end
end
