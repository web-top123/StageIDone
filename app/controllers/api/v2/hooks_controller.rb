class Api::V2::HooksController < Api::V2::BaseController
  before_filter :find_hook, except: [:index, :create]

  def index
    paginate json: @current_user.hooks.map{|h| display_hook(h)}
  end

  def show
    render json: display_hook(@hook)
  end

  def create
    @team = Team.find_by(hash_id: create_hook_params[:team_id])
    unless @team.active_users.include?(@current_user)
      error!('You do not have access to that team', 401) and return
    end
    hook = @current_user.hooks.build( create_hook_params.except(:team_id).merge(team: @team) )
    if hook.save
      render json: display_hook(hook), status: 201
    else
      error!(hook.errors.full_messages.join(' '), 400)
    end
  end

  def update
    if update_hook_params[:team_id]
      @team = Team.find_by(hash_id: update_hook_params[:team_id])
      unless @team.active_users.include?(@current_user)
        error!('You do not have access to that team', 401) and return
      end
    end
    attrs = update_hook_params.except(:team_id)
    attrs.merge!(team: @team) if @team
    if @hook.update_attributes(attrs)
      render json: display_hook(@hook)
    else
      error!(hook.errors.full_messages.join(' '), 400)
    end
  end

  def destroy
    if @hook.destroy
      render json: {deleted: true, id: @hook.id}
    else
      error!(hook.errors.full_messages.join(' '), 400)
    end
  end

  private

  def display_hook(hook)
    hook.as_json(
      only: [:id, :target_url, :created_at, :updated_at],
      include: [
        {team: {only: [:hash_id, :name]}},
        {user: {only: [:hash_id, :full_name, :email_address]}}
      ]
    )
  end

  def create_hook_params
    params.require(:target_url)
    params.require(:team_id)
    params.permit(:target_url, :team_id)
  end

  def update_hook_params
    params.permit(:target_url, :team_id)
  end

  def find_hook
    # Use find_by to return nil instead of exception
    @hook = Hook.find_by(id: params[:id])
    unless @hook && @current_user == @hook.user
      error!('You do not have access to that webhook', 401) and return
    end
  end
end
