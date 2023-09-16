class Api::V2::TeamsController < Api::V2::BaseController
  before_filter :find_team, except: [:index,:create]

  # GET
  # http://localhost:3000/api/v2/teams?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af
  def index
    @teams = @current_user.active_teams.order('created_at desc')
    # map{|t| t.as_json(only: public_attrs)}
    render formats: :json
    # paginate json: @current_user.active_teams.map{|t| t.as_json(only: public_attrs)}
  end 

  # POST
  # http://localhost:3000/api/v2/teams?name=new team1&api_token=5d479058df9ef42202cb15b3174556f37e10b17c
  def create
    @organization = Organization.find_by(hash_id: params[:organization_id])
    # @organization = @current_user.organizations.where(:billing_name => @current_user.full_name , :billing_email_address => @current_user.email_address).first
    # @organization = @current_user.organizations.where(:billing_email_address => @current_user.email_address).first
    @team = @organization.teams.new(:name => params[:name],:organization_id => @organization.id,:owner_id => @current_user.id)
    @team.save
    TeamMembership.create(team: @team, user: @current_user)
    render formats: :json
  end

  # GET
  # http://localhost:3000/api/v2/teams/2bc8ab91ac4b?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af
  def show
    if @team.organization.stripe_subscription_status == "trialing" || @team.organization.stripe_subscription_status == "active"
      render formats: :json # Renders the jbuilder
    else
      error!('You do not have access to that team.', 401) and return
    end
  end

  # POST
  # http://localhost:3000/api/v2/teams/bbb5464cffb5?name=new team1sadssadasdsadsdsdasda&api_token=348360ad72137d1428494eec352fcd2e71abf19a
  def update
    # @organization = @team.organization
    # @org_owner = User.find(@organization.organization_memberships.where(:role => "owner").pluck(:user_id)[0])
    if @team.owner_id == @current_user.id
      @team.update_attributes(team_params)
      render formats: :json
    else
      error!('You do not have access to the team.', 401) and return
    end
  end
 
  # GET
  # http://localhost:3000/api/v2/teams/2bc8ab91ac4b/members?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af
  # Members are really users.
  def members
    @members = @team.users
    render formats: :json
  end

  # GET
  # http://localhost:3000/api/v2/teams/2bc8ab91ac4b/entries?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066af
  # Team entries vs personal entries. Only for listing.
  def entries
    entries = @team.entries.eager_load(:team).order('entries.created_at desc')
    paginate json: entries.map{|e| e.pretty_format}
  end

  private

  def team_params
    params.permit(:name, :public,:owner_id)
  end

  def public_attrs
    [:hash_id, :name, :created_at, :updated_at]
  end

  def find_team
    @team = Team.find_by(hash_id: params[:id])
    unless @team && @team.active_users.include?(@current_user)
      error!('You do not have access to that team', 401) and return
    end
  end
end
