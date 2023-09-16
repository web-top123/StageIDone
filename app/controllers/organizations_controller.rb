class OrganizationsController < ApplicationController
  before_action :require_login
  before_action :check_for_overdue, only: [:show, :settings, :stats]
  before_action :require_verification, only: [:new]
  skip_after_action :verify_authorized, only: :default

  rescue_from Pundit::NotAuthorizedError do
    redirect_to controller: :errors, action: :incorrect_organization
  end

  def default
    if last_team_visited.present?
      redirect_to last_team_visited
    elsif current_user.active_teams.where.not(organization_id: nil).any?
      redirect_to current_user.active_teams.where.not(organization_id: nil).first # save default team at some point
      return
    elsif current_user.show_personal_team && current_user.personal_teams.any?
      redirect_to current_user.personal_team
      return
    elsif current_user.active_organizations.any?
      redirect_to current_user.active_organizations.first
      return
    else
      redirect_to [:new, :organization]
      return
    end
  end

  def new
    authorize Organization

    @organization = Organization.new
    render action: 'new', layout: 'modal'
  end

  def create
    authorize Organization

    @organization = Organization.new(organization_params.merge(billing_name: current_user.full_name, billing_email_address: current_user.email_address))

    if @organization.save
      OrganizationMembership.create! user: current_user, organization: @organization, role: 'owner'
      redirect_to [:new, @organization, :team]
    else
      render action: 'new', layout: 'modal'
    end
  end

  def show
    @organization = current_organization

    authorize @organization
    if current_organization.trial_elapsed_and_needs_to_upgrade?
      logger.info("--Userrrr trial Subscription Expired Show----")
      redirect_to([:overdue, current_organization])
    end
    if @organization.teams.empty? # TODO: if the org is overdue _and_ this is true, it'll freak out
      redirect_to [:new, @organization, :team]
      return
    end
  end

  def export
    raw_dates = [
      (params[:end_date] ? Date.parse(params[:end_date]) : Date.current),
      (params[:start_date] ? Date.parse(params[:start_date]) : Date.current)
    ]
    @start_date, @end_date = raw_dates.min, raw_dates.max

    @organization = current_organization
    @entries = @organization.entries.for_period(@start_date, @end_date)

    authorize @organization

    respond_to do |format|
      format.csv { send_data @entries.to_csv }
    end
  end

  def stats
    @organization = current_organization
    @end_date = params[:date] ? Date.parse(params[:date]) : Date.current
    @range = params[:range] ? params[:range].to_i : 7
    @start_date = @end_date - (@range - 1).days

    authorize @organization

    @most_active_teams = @organization.most_active_visible_teams_in_period(@start_date, @end_date)
    @most_active_users = @organization.most_active_users_in_period(@start_date, @end_date)
    @dreamer =  @organization.wof_dreamer_for_period(@start_date, @end_date)
    @loquacious =  @organization.wof_loquacious_for_period(@start_date, @end_date)
    @busiest =  @organization.wof_busiest_for_period(@start_date, @end_date)
    @entries = @organization.entries.includes(:team, :user)
                                    .includes(team: [:organization])
                                    .includes(reactions: [:user, :reactable])
                                    .where("teams.public = true")
                                    .where(entries: { occurred_on: @start_date..@end_date })
                                    .order('occurred_on desc')

  end

  def settings
    @organization = current_organization

    authorize @organization
  end

  def billing
    @organization = current_organization

    authorize @organization

    render partial: 'billing', locals: { organization: @organization }
  end

  def billing_form
    @organization = current_organization

    authorize @organization

    render partial: 'billing_form', locals: { organization: @organization }
  end

  def billing_save
    @organization = current_organization

    authorize @organization

    if @organization.update_attributes(organization_billing_params)
      render partial: 'billing', locals: { organization: @organization }
    else
      render partial: 'billing_form', locals: { organization: @organization }
    end
  end

  def customize
    @organization = current_organization

    authorize @organization

    @organization.update_attributes(customize_organization_params)
    render action: 'settings'
  end

  def invoices
    @organization = current_organization

    authorize @organization

    render partial: 'invoices', locals: { organization: @organization }
  end

  def update
    @organization = current_organization

    authorize @organization

    @organization.update_attributes(organization_params)
    render partial: 'form', locals: { organization: @organization }
  end

  def saml_save
    @organization = current_organization

    authorize @organization

    @organization.update_attributes(organization_saml_params)
    render partial: 'saml', locals: { organization: @organization }
  end

  # old_code
  # def overdue
  #   @organization = current_organization

  #   authorize @organization

  #   if @organization.owners.include?(current_user)
  #     render action: 'overdue_owner', layout: 'modal'
  #   else
  #     render action: 'overdue_member', layout: 'modal'
  #   end
  # end

  def overdue
    @organization = current_organization

    authorize @organization
    logger.info("--Userrrr #{@organization.stripe_subscription_status}----")
    if @organization.stripe_subscription_status != "past_due"
      if @organization.owners.include?(current_user)
        render action: 'overdue_owner', layout: 'modal'
      else
        render action: 'overdue_member', layout: 'modal'
      end
    else
      flash[:notice] = "Your account is past due. Please update your credit card details on billing page."
      render action: 'settings'
    end
  end

  private

  def current_organization
    @current_organization ||= Organization.find_by(hash_id: params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name)
  end

  def customize_organization_params
    params.require(:organization).permit(:logo)
  end

  def organization_saml_params
    params.require(:organization).permit(:saml_meta_url)
  end

  def organization_billing_params
    params.require(:organization).permit(:billing_name, :stripe_token)
  end

  def check_for_overdue
    if current_organization.trial_elapsed_and_needs_to_upgrade?
      # logger.info("--Userrrr trial Subscription Expired----")
      redirect_to([:overdue, current_organization])
    end
  end

  def last_team_visited
    @last_team_visited ||= current_user.active_teams.where(hash_id: cookies[:last_team_id]).first
  end
end
