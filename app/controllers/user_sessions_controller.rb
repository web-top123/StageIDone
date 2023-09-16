class UserSessionsController < ApplicationController
  before_action :require_login, only: [:destroy]
  before_action :require_not_logged_in, only: [:new, :create]
  after_action :prepare_intercom_shutdown, only: [:destroy]
  skip_after_action :verify_authorized
  layout 'register', only: [:new, :create]

  def new
    respond_to do |format|
      # if session[:attempt]
      #   if session[:attempt] > 2
      #     @show_checkbox_recaptcha = true
      #   end
      # else
      #   session[:attempt] = 0
      # end

      format.html { render :new }
      format.json { head :no_content }
    end
  end

  def create
    if Rails.env.development? && @user = login(params[:email_address], params[:password], true)
      logger.info("--Userrrr login 17----")
      # session.delete(:attempt)
      redirect_to(next_path_for_user(@user)) && return
      # redirect_back_or_to(next_path_for_user(@user)) && return
    elsif !Rails.env.development? && verify_recaptcha(model: @user) && @user = login(params[:email_address], params[:password], true)
      logger.info("--Userrrr login 17----")
      redirect_to(next_path_for_user(@user)) && return
    else
      flash.now[:error] = 'Please enter a correct email , password and verify that you are not a robot.'
      render action: 'new'
    end
  end

  def oauth
    login_at(params[:provider])
  end

  def oauth_callback
    provider = params[:provider] || 'google' # the hooks are there to allow providers other than google

    begin
      if @user = login_from(provider)
        redirect_back_or_to(next_path_for_user(@user)) && return
      elsif @user = login_with_email(provider)
        redirect_back_or_to(next_path_for_user(@user), notice: "Contact our support team to enable your account") && return
      else
        @user = create_from(provider)
        @user.verify!
        reset_session # protect from session fixation attack
        auto_login(@user)
        redirect_back_or_to(next_path_for_user(@user.reload)) && return
      end
    rescue => ex
      redirect_to login_path, notice: "Failed to login from #{provider.titleize}. #{ex}"
    end
  end

  def destroy
    logout
    redirect_to root_path
  end

  private

  def prepare_intercom_shutdown
    IntercomRails::ShutdownHelper::intercom_shutdown_helper(cookies)
  end

  # Before using the Sorcery external lib for google signup we supported any user being able to sign in via their
  # google email.  This uses sorcery provider logic to support that existing feature
  def login_with_email(provider)
    user_hash = sorcery_fetch_user_hash(provider)
    user_info = user_hash[:user_info]
    if user = User.with_deleted.find_by(email_address: user_info['email'].downcase)
      auto_login(user)      
      user.add_provider_to_user(provider, user_hash[:uid])
      user
    end
  end
end
