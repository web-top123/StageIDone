class Admin::TeamsController < Admin::ApplicationController
  def index
    if params[:filter_field].present? &&
       (params[:filter_field].downcase != 'all') &&
       Team.filter_fields.include?(params[:filter_field].downcase)

      @teams = Team.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).page(params[:page])
      @scope_count = Team.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).size
      @filter_params = params.slice(:filter_field, :filter_value)

      if @teams.size == 1
        redirect_to [:admin, @teams.first]
        return
      end
    else
      @scope_count = Team.alphabetically.count
      @teams = Team.alphabetically.page(params[:page])
    end
  end

  def show
    @filter_params = params.slice(:filter_field, :filter_value)
    @team = Team.find_by(hash_id: params[:id])
  end

  def update
    @team = Team.find_by(hash_id: params[:id])
    @team.update_attributes(team_params)
    redirect_to [:admin, @team]
  end

  private

  def team_params
    params.require(:team).permit(
      :name,
      :prompt_done,
      :prompt_goal,
      :prompt_blocked,
      :public
    )
  end
end
