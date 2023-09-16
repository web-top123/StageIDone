class UsersController < ApplicationController
  before_action :require_login, except: [:new, :create, :reset_password, :request_reset, :verify]
  before_action :require_not_logged_in, only: [:new, :create, :reset_password, :request_reset]
  skip_after_action :verify_authorized, only: [:new, :create, :go_by_for_full_name, :reset_password, :request_reset, :verify, :reset_api_token]
  layout 'register', only: [:new, :create, :reset_password, :request_reset]

  def new
    # TODO handle redeemed invitations, invalid invitations, etc
    if params[:invitation_code]
      @invitation = Invitation.where(invitation_code: params[:invitation_code]).first
      @user = User.new(full_name: @invitation.full_name, email_address: @invitation.email_address, invitation_code: @invitation.invitation_code)
    elsif params[:email_address] || params[:full_name]
      @user = User.new(email_address: params[:email_address], full_name: params[:full_name])
    else
      @user = User.new
    end
  end

  def create
    attrs = new_user_params
    attrs[:time_zone] = ActiveSupport::TimeZone::MAPPING.key(attrs[:time_zone])
    @user = User.new(attrs)
    existing_user = User.find_by_email(attrs[:email_address])
    if Rails.env.development? && @user.save
      auto_login(@user)
      if !existing_user && attrs[:invitation_code].present?
        team = @user.teams.last
        CreateTipsEntriesWorker.perform_async("#{request.base_url}/t/",
                                              @user.id,
                                              @user.time_zone,
                                              team.id,
                                              team.hash_id,
                                              nil)
      end
      redirect_to('/onboard/one')
    elsif !Rails.env.development? && verify_recaptcha(model: @user) && @user.save
      auto_login(@user)
      if !existing_user && attrs[:invitation_code].present?
        team = @user.teams.last
        CreateTipsEntriesWorker.perform_async("#{request.base_url}/t/",
                                              @user.id,
                                              @user.time_zone,
                                              team.id,
                                              team.hash_id,
                                              nil)
      end
      redirect_to('/onboard/one')
    else
      render action: "new"
    end
  end

  def reset_api_token
    current_user.reset_api_token!
    render partial: 'api_token', locals: { user: @user }
  end

  def verify # marks the user as verified
    if params[:verification_token].present?
      @user = User.where('verification_token_expires_at > ?', Time.zone.now).
                   where(verification_token: params[:verification_token]).first
      if @user
        @user.verify!
        flash[:notice] = "Great! Your email address is now verified."
        redirect_to root_path
        return
      elsif User.where(verification_token: params[:verification_token]).any?
        @user = User.find_by(verification_token: params[:verification_token])
        VerificationEmailWorker.perform_async(@user.id)
        flash[:notice] = "That verification link has expired, so we sent you another. Check your email and click the link."
        redirect_to root_path
        return
      end
    end
    flash[:notice] = "Hmmm. We're having trouble validating that verification link."
    redirect_to root_path
  end

  def request_reset # you give me an email & i send you a token

    @email_address = params[:email_address]
    @user = User.find_by(email_address: @email_address)
    if @email_address && @user
      UserMailer.reset_password(@user).deliver_now
      # PasswordEmailWorker.perform_async(@user.id)
    end
  end

  def reset_password # you give me token & i let you change password
    @user = User.load_from_reset_password_token(params[:password_reset_token])
    redirect_to(reset_password_users_path) unless @user.present?

    if params[:password].present? &&
       params[:confirm_password].present? &&
       params[:password] == params[:confirm_password]

      if @user.change_password!(params[:confirm_password])
        auto_login(@user)
        redirect_to root_path
        return
      end
    end
  end

  def update # scoped to current_user
    @user = current_user

    authorize @user

    @user.update_attributes(update_user_params)
    render partial: 'form', locals: { user: @user }
  end

  def change_password # scoped to current_user
    @user = current_user

    authorize @user

    if @user.valid_password? params[:old_password]
      @user.update_attributes(change_password_user_params)
    else
      @user.errors.add(:base, "Old password is invalid")
    end

    render partial: 'change_password', locals: { user: @user }
  end

  def personalize # scoped to current_user
    @user = current_user

    authorize @user

    @user.update_attributes(personalize_user_params)
    render action: 'settings'
  end

  def settings # scoped to current_user
    @user = current_user

    authorize @user

    @integration_links = IntegrationLink.for_user(@user)
  end

  def show
    @organization = Organization.find_by(hash_id: params[:organization_id])
    @current_organization = @organization

    authorize @organization, :user?

    @user = @organization.users.with_deleted.find_by(hash_id: params[:id])
    # @entries = @user.entries.for_organization(@organization).order('occurred_on desc')
    @entries = @user.entries.for_organization(@organization).order('occurred_on desc').page(params[:page]).per(10)

  end

  def go_by_for_full_name
    namae = Namae::Name.parse(params['full_name'])
    render text: namae.given
  end

  private

  def new_user_params
    params.require(:user).permit(:email_address, :phone_number, :password, :full_name, :invitation_code, :time_zone)
  end

  def update_user_params
    params.require(:user).permit(:email_address, :phone_number, :full_name, :time_zone, :show_personal_team)
  end

  def change_password_user_params
    params.require(:user).permit(:password)
  end

  def personalize_user_params
    params.require(:user).permit(:portrait)
    puts params.require(:user)
  end
end
