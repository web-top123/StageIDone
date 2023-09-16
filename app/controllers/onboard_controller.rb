class OnboardController < ApplicationController
  layout 'onboarding'
  before_action :require_login
  ## Onboard new users

  def onboard_notice
      @user = current_user
      authorize @user
      logger.info("--Userrrr login 144----")
      render action: 'onboard_notice'
  end

  def onboard_one
    @user = current_user

    authorize @user
    if @user.active_organizations.any? # if somebody's been invited and is already in an org
      @user.touch(:onboarded_at)
      redirect_to(root_path) && return
    end
  end

  def onboard_one_save
    @user = current_user

    authorize @user
    if @user.update_attributes(onboard_user_params)
      if @user.teams.non_personal.any?
        @team = @user.teams.last
        entry_titles = []
        if cookies[:new_goal].present?
          entry_titles << cookies[:new_goal]
          cookies.delete :new_goal
        end
        CreateTipsEntriesWorker.perform_async("#{request.base_url}/t/",
                                              current_user.id,
                                              current_user.time_zone,
                                              @team.id,
                                              @team.hash_id,
                                              entry_titles)
        @organization = @team.organization
        @organization.plan_level = "small"
        @organization.plan_interval = "monthly"
        subscription = Stripe::Subscription.create({
          customer: @organization.stripe_customer_token,
          plan:     @organization.plan_stripe_id,
          quantity: @organization.users.count,
          trial_end: @organization.on_trial? ? @organization.trial_ends_at.to_i : 'now',
        })
        @organization.stripe_subscription_status = subscription.status
        @organization.save
        redirect_to('/onboard/two')
      else
        @user.touch(:onboarded_at)
        redirect_to root_path
      end
    else
      render action: 'onboard_one'
    end
  end

  def onboard_two
    @user = current_user
    @team = @user.teams.last
    @organization = @team.organization

    authorize @user
  end

  def onboard_two_save
    user = current_user
    team = user.teams.last
    organization = team.organization

    invitations = []
    team_memberships = []

    invitation_params[:email_addresses].split(',').uniq.map(&:strip).each do |email_address|
      existing_user = organization.active_users.find_by(email_address: email_address)
      if existing_user.present?
        team_memberships << TeamMembership.find_or_initialize_by(team_id: team.id, user_id: existing_user.id)
      else
        invitations << Invitation.new(organization: organization, sender: current_user, email_address: email_address, team_ids: [team.id])
      end
    end

    authorize user

    team_memberships.each(&:join!)
    invitations.each(&:save!)

    user.touch(:onboarded_at)
    redirect_to root_path
  end

  def onboard_exit
    @user = current_user

    authorize @user
    @user.touch(:onboarded_at)

    redirect_to root_path
  end


  ## Onboard migrated users

  def migrate_one
    @user = current_user

    authorize @user
  end

  def migrate_one_save
    @user = current_user

    authorize @user

    if @user.update_attributes(migrate_user_params)
      redirect_to('/migrate/two')
    else
      render action: 'migrate_one'
    end
  end

  def migrate_two
    @user = current_user

    authorize @user
  end

  def migrate_two_save
    @user = current_user

    authorize @user

    if @user.touch(:onboarded_at)
      redirect_to root_path
    else
      render action: 'migrate_two'
    end
  end

  private

  def onboard_user_params
    params.require(:user).permit(:full_name, :go_by_name, :portrait, :first_team_name)
  end

  def migrate_user_params
    params.require(:user).permit(:full_name, :go_by_name, :portrait)
  end

  def invitation_params
    params.require(:invitations).permit(:email_addresses)
  end
end
