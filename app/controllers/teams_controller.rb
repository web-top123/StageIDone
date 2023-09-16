class TeamsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError do
    redirect_to controller: :errors, action: :incorrect_organization
  end

  before_action :require_login
  before_action :check_for_overdue_organization, only: [:show, :new, :settings]
  before_action :archive_notifications_for_team_day, only: :show
  before_action :redirect_to_entry_if_entry_id_present, only: :show

  layout 'modal', only: [:new, :create]

  def new
    @organization = Organization.find_by(hash_id: params[:organization_id])
    authorize Team.new(organization: @organization)
    @team = Team.new(organization: @organization)
  end

  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @team = current_team
    @team_active_users = @team.active_users
    @team_entries = @team.entries
    authorize @team

    set_last_team
    @organization = current_organization
    @entry = Entry.new(user: current_user, team: @team, occurred_on: @date, status: 'done')
    if @team.personal?
      if current_user.created_at >= "2008-12-17"
        if current_user.show_personal_team == true
          current_user_organizations = current_user.organizations
          if current_user.organizations.first.present?
            activeOrg = 0;
            current_user.organizations.all.each do |u|
              if u.stripe_subscription_status == "trialing" || u.stripe_subscription_status == "active"
                activeOrg += 1
              end
            end
            if activeOrg > 0
              render 'personal'
            else
              flash[:notice] = "Your subscription is expired, Please renew your plan."
              redirect_to organization_upgrade_path(current_user.organizations.last)
            end
          else
            redirect_to('/onboard/one')
          end
        end
      else
        render 'personal'
      end
    else
      users = @team.members_at(@date).alphabetically
      @users_with_entries = users.uniq
                                 .joins(:entries)
                                 .where(entries: { team_id: @team.id})
                                 
      arr = []
      tips = []
      @user_team_entries_count = []
      @users_with_entries.each do |user|
        user_entries = user.entries
        user_team_entries = user_entries.for_team(@team)
        user_team_entries_occurred_on = user_team_entries.where('occurred_on <= ?', @date)
        entries_blocked = user_team_entries_occurred_on.blockers.count
        entries_done = user_team_entries.dones.where('occurred_on = ?', @date).count
        entries_goal = user_team_entries_occurred_on
                           .goals
                           .where(completed_on: nil, archived_at: nil)
                           .count
        entries_tip = user_team_entries_occurred_on.tips.count
        entries_not_tip = user_team_entries_occurred_on.not_tips
                                           .reject{ |g| (g.status == 'done' && g.occurred_on != @date) || 
                                                        (g.status == 'goal' && g.occurred_on != @date && g.completed_on != nil) }.first         
        entries_count = (entries_done + entries_goal + entries_blocked) - entries_tip
        user_team_entries_count = {}
        user_team_entries_count[:user_id] = user.id
        user_team_entries_count[:user_entries_count] = entries_count
        @user_team_entries_count << user_team_entries_count
        arr << user if entries_blocked == 0 && entries_done == 0 && entries_goal == 0
        tips << user if user != current_user && !entries_not_tip.present? && entries_tip != 0
      end

      @users_with_entries = @users_with_entries.reject{|u| u == current_user}
      @users_with_entries.unshift(current_user)
      @users_with_entries = @users_with_entries.reject { |e| arr.include? e } if arr.any?
      @users_with_entries = @users_with_entries.reject { |e| tips.include? e } if tips.any?
      @users_without_entries = users.reject{|u| u == current_user} - @users_with_entries
      current_user_organizations_last = current_user.organizations.last
      if !current_user_organizations_last.stripe_subscription_status?
        if current_organization.owners.include?(current_user)
          flash[:notice] = "Your subscription is expired, Please renew your plan."
          redirect_to organization_upgrade_path(current_user_organizations_last)
        else
          flash[:notice] = "Your subscription is expired, Please Contact to your organization owner."
          redirect_to subcription_failes_path(current_user_organizations_last)
        end
      else
        render 'show'
      end
    end
  end

  def join
    team_membership = TeamMembership.find_or_initialize_by(team_id: current_team.id, user_id: current_user.id)

    authorize team_membership, :create?

    team_membership.join!

    redirect_to current_team
  end

  def create
    @organization = Organization.find_by(hash_id: params[:organization_id])
    @team = Team.new(team_params.merge(organization: @organization ,owner_id: @current_user.id))
    authorize @team

    if @team.save
      TeamMembership.create(team: @team, user: @current_user)
      redirect_to @team
    else
      render action: "new"
    end
  end

  def update
    @team = current_team

    authorize @team

    @organization = current_organization
    if @team.owner_id == @current_user.id
      @team.update_attributes(team_params)
    end
    render partial: 'form', locals: { team: @team }
  end

  def customize
    @team = current_team

    authorize @team

    @organization = current_organization
    @team.update_attributes(customize_params)
    render partial: 'customize', locals: { team: @team }
  end

  def settings
    @team = current_team

    authorize @team

    @organization = current_organization
    @integration_links = IntegrationLink.for_team(@team)

    if @team.personal?
      render action: 'settings_personal'
    else
      render action: 'settings'
    end
  end

  def calendar_month
    @team = current_team

    authorize @team

    @organization = current_organization
    @date = Date.parse(params[:date])
    render partial: 'calendar', locals: { team: @team, date: @date }
  end

  def brief
    team = current_team
    team_active_users = team.active_users
    team_entries = team.entries
    date = params[:date] ? Date.parse(params[:date]) : Date.current

    authorize team
    if team.personal?
      render partial: 'personal_day', locals: { team: team, date: date }
    else
      users_with_entries = team_active_users.alphabetically.reject { |u|
        u.entries.for_team(team).for_day(date).empty? || (u == current_user)
      }

      users_without_entries = team_active_users.alphabetically.reject { |u|
        u.entries.for_team(team).for_day(date).any? || (u == current_user)
      }
      render partial: 'team_day', locals: { users_with_entries: users_with_entries, users_without_entries: users_without_entries, 
                                            date: date, team: team, team_organization: team.organization, 
                                            team_active_users: team_active_users, team_entries: team_entries}
    end
  end
  def user_entry_listing
    team = current_team
    authorize team
    user = User.find(params[:user_id])
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    user_entries = user.entries.includes(:user, :team, :prompting_goal).for_team(team)
    @entry = Entry.new(user: user, team: team, occurred_on: date, status: 'done')
    render partial: 'user_day', locals: { user: user, cur_date: date, team: team, user_entries: user_entries,
                                          team_organization: team.organization}
  end

  def search
    @team = current_team

    authorize @team

    @query = params[:q]
    @organization = current_organization
    @entries = Entry.for_team(@team).order('occurred_on desc').basic_search(body: @query)
  end

  def calendar
    @team = current_team
    @organization = current_organization

    authorize @team

    @calendar_presenter = CalendarPresenter.new(params[:date], @team)

    hash_for_month_group_by_user_and_occurred_on =
        @team.entries.for_month_group_by_user_and_occurred_on(@calendar_presenter.month)

    @entries_by_occured_on_by_user = hash_for_month_group_by_user_and_occurred_on[:entries]
    @users_with_entries = hash_for_month_group_by_user_and_occurred_on[:users]
  end

  def export
    raw_dates = [
      (params[:end_date] ? Date.parse(params[:end_date]) : Date.current),
      (params[:start_date] ? Date.parse(params[:start_date]) : Date.current)
    ]
    @start_date, @end_date = raw_dates.min, raw_dates.max

    @team = current_team
    @entries = @team.entries.includes(:user).for_period(@start_date, @end_date)

    authorize @team

    respond_to do |format|
      format.csv { send_data @entries.to_csv }
    end
  end

  def stats
    @end_date = params[:date] ? Date.parse(params[:date]) : Date.current
    @range = params[:range] ? params[:range].to_i : 30
    @start_date = @end_date - (@range - 1).days
    @team = current_team

    authorize @team

    @organization = current_organization

    @most_active_users = @team.most_active_users_in_period(@start_date, @end_date)
    @dreamer =  @team.wof_dreamer_for_period(@start_date, @end_date)
    @loquacious =  @team.wof_loquacious_for_period(@start_date, @end_date)
    @busiest =  @team.wof_busiest_for_period(@start_date, @end_date)
  end

  def destroy
    @team = current_team
    authorize @team
    @organization = current_organization
    if @team.owner_id == current_user.id || @team.organization.owners.include?(current_user)
      @team.destroy!
    end
    if @organization
      redirect_to @organization
    else
      redirect_to root_path
    end
  end

  private

  def current_team
    @current_team ||= begin
      if params[:id]
        Team.find_by!(hash_id: params[:id])
      end
    end
  end

  def current_organization
    @current_organization ||= current_team ? current_team.organization : Organization.find_by!(hash_id: params[:organization_id])
  end

  def team_params
    params.require(:team).permit(
      :name,
      :public,
      :owner_id
    )
  end

  def customize_params
    params.require(:team).permit(
      :prompt_done,
      :prompt_goal,
      :prompt_blocked,
      :enable_expandable_entries_box,
      :enable_entry_timestamps,
      :carry_over_goals
    )
  end

  def check_for_overdue_organization
    if current_organization && current_organization.trial_elapsed_and_needs_to_upgrade?
      redirect_to([:overdue, current_organization])
    end
  end

  def archive_notifications_for_team_day
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    Notification.archive!(current_user, date, current_team.id)
  end

  def redirect_to_entry_if_entry_id_present
    if params[:entry_id].present?
      skip_authorization
      redirect_to team_path(params[:id], date: params[:date], anchor: params[:entry_id]) and return
    end
  end

  def set_last_team
    cookies[:last_team_id] =  {
      value: @team.hash_id,
      expires: 1.month.from_now
    }
  end

  # def check_card_details_present
  #   if current_user.created_at >= "2017-12-17"
  #     if !current_user.organizations.last.stripe_subscription_status?
  #       @organization = current_organization
  #       @organization.plan_level = "basic"
  #       @organization.plan_interval = "yearly"
  #     end
  #   end
  # end
end
