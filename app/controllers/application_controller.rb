class ApplicationController < ActionController::Base
  include Pundit
  include OrganizationHelper
  protect_from_forgery
  around_filter :user_time_zone, if: :current_user
  after_action :verify_authorized
  before_action :update_last_seen_at
  before_action :try_to_verify_user
  before_action :set_raven_context

  before_filter :ensure_domain

  #APP_DOMAIN = 'app.idonethis.com'
  def ensure_domain
      unless request.env['HTTP_HOST'] == ENV['DOMAIN_NAME'] || request.env['HTTP_HOST'] == 'idt-two.herokuapp.com' || request.env['HTTP_HOST'] == 'idt-two-staging.herokuapp.com' || request.env['HTTP_HOST'] == 'localhost:3000'
         # HTTP 301 is a "permanent" redirect
         redirect_to "https://#{ENV['DOMAIN_NAME']}"
      end
  end

  #  def ensure_domain
  #   if !Rails.env.development?
       #if request.env['HTTP_HOST'] != APP_DOMAIN
  #     if request.base_url != APP_DOMAIN
         # HTTP 301 is a "permanent" redirect
  #       redirect_to "https://#{APP_DOMAIN}"
  #     end
  #   end
  #end

  protected

  def set_raven_context
    user_details = {}

    user_details.merge!(
      'id' => current_user.id,
      'email_address' => current_user.email_address,
      'full_name' => current_user.full_name,

    ) if current_user

    user_details.merge!(
      'idt1_username' => session[:idt1_username]
    ) if session[:idt1_username]

    Raven.user_context(user_details)
    Raven.extra_context(params: params.to_hash, url: request.url)
  rescue StandardError => e
    # We _really_ don't want this to fail and throw an exception, as its related
    # to the exception-catching itself
    Raven.capture e
    true
  end

  def user_time_zone(&block)
    logger.info("--Userrrr #{current_user.time_zone}----")
    Time.use_zone(current_user.time_zone, &block)
  end

  def current_admin
    @current_admin ||= AdminUser.find_by(id: session[:admin_user_id])
  end

  def require_not_logged_in
    if logged_in?
      redirect_to root_path
      return false
    end
  end

  def require_admin
    if Rails.env.production? && current_admin.nil?
      redirect_to new_admin_session_path
      return false
    end
  end

  def not_authenticated
    respond_to do |format|
      format.html { redirect_to login_path }
      format.xml { head :forbidden }
      format.json { head :forbidden }
    end
  end

  def require_verification
    return false unless logged_in?
    return true unless current_user.needs_verification?

    VerificationEmailWorker.perform_async(current_user.id)
    flash[:notice] = "We need to verify your email address. We just emailed you a link: click it!"

    respond_to do |format|
      format.html { redirect_to(settings_user_path) }
      format.xml { head :forbidden }
      format.json { head :forbidden }
    end
  end

  def try_to_verify_user
    # return if there's NOT (a param OR session variable) OR if (there's a user AND the
    # user is already verified)

    return if verification_param_is_not_present? or current_user_is_verified?

    verification_token = params[:v].present? ? params[:v] : session[:verification_token]

    user = User.where('verification_token_expires_at > ?', Time.zone.now).
                where(verification_token: verification_token).first

    if user && logged_in? && (user == current_user)
      session[:verification_token] = nil
      user.verify!
    elsif user
      session[:verification_token] = verification_token
    end
  end

  def update_last_seen_at
    return if !current_user || (current_user.last_seen_at.present? && ((Time.zone.now - current_user.last_seen_at) < 10.minutes))
    current_user.update_column :last_seen_at, Time.zone.now
  end

  private

  def current_user_is_verified?
    (current_user && current_user.verified?)
  end

  def verification_param_is_not_present?
    !(params[:v].present? || session[:verification_token].present?)
  end

  def next_path_for_user(user)
    if user.onboarded?
      if !user.organizations.any? # needs an org
          return "/onboard/one"
      else # they don't need onboarding
        activeOrg = 0;
        user.organizations.all.each do |u|
          if u.stripe_subscription_status == "trialing" || u.stripe_subscription_status == "active"
            activeOrg += 1
          end
        end
        if activeOrg > 0
          return root_path
        else
          flash[:notice] = "Your subscription is expired, Please renew your plan."
          return organization_upgrade_path(current_user.organizations.last)
        end
      end
    else # user is not onboarded
      if user.migrated_from_legacy_at.present? # is a migrated user
        if user.needs_post_migration_onboarding? # TODO change method name to something like 'needs info'
          return "/migrate/one"
        else
          return "/migrate/two"
        end
      else # is not a migrated user
        if !user.organizations.any? # needs an org
          return "/onboard/one"
        else # they don't need onboarding
          user.update_column(:onboarded_at, Time.zone.now)
          return root_path
        end
      end
    end
  end
end
