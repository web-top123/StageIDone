class MigrationController < ApplicationController
  skip_after_action :verify_authorized
  layout 'onboarding'

  before_action :set_username, except: [:connect, :oauth_callback]

  def connect
  end

  def confirm
    (@user, @org, @owned_teams) = Idt1Migrator.org_and_teams(@username)
    @idt2_user = User.find_by(email_address: @user[:email].downcase) if @user

    if @idt2_user
      auto_login(@idt2_user)
      redirect_to(next_path_for_user(@idt2_user))
    end

    if !@idt2_user && @user
      @source_data = Rails.cache.fetch("migration_id_#{@user[:id]}", expires_in: 20.minutes) do
        Idt1Migrator.data_to_migrate(@user[:id])
      end
    end

    if @source_data
      @source_errors = Idt1Migrator.validate(@source_data, override_validation)
      if @source_errors && @source_errors.any?
        msg = "Migration error for username #{@username}: #{ @source_errors.join(', ') }"
        Raven.capture_message msg
        Rails.logger.error msg
      end
    end
  end

  def execute_migration
    (@user, @org, @owned_teams) = Idt1Migrator.org_and_teams(@username)
    @source_data = Rails.cache.fetch("migration_id_#{@user[:id]}", expires_in: 20.minutes) do
      Idt1Migrator.data_to_migrate(@user[:id])
    end
    # Assuming every entry insertion is at least 10ms, 3000 entries would be
    # 300s, enough to time out on heroku. 2000 might still be cutting it too
    # close, giving us only 15ms per query to do everything. 1000 at least gives
    # us 30ms per query, so will be nice for smaller people.
    if @source_data[:entries].length < 1000
      Idt1Migrator.migrate(@source_data, disable_digest_and_reminders, override_validation)
      u = User.find_by(email_address: @user[:email].downcase)
      auto_login(u)
      redirect_to(next_path_for_user(u))
    else
      MigrationWorker.perform_async(@username, disable_digest_and_reminders, override_validation)
      render :success
    end
  rescue StandardError => e
    Raven.capture_exception(e)
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    render :failure
  end

  def oauth_callback
    session[:idt1_username] = request.env['omniauth.auth']['uid']
    redirect_to migrate_confirm_path
  end

  private

  def override_validation
    params[:override] == ENV['MIGRATION_OVERRIDE_KEY'] && params[:validate] == '0'
  end

  def disable_digest_and_reminders
    params[:override] == ENV['MIGRATION_OVERRIDE_KEY'] && params[:disable_digest_and_reminders] == '1'
  end

  def set_username
    @username = if ENV['MIGRATION_OVERRIDE_KEY'] && (params[:override] == ENV['MIGRATION_OVERRIDE_KEY'])
      params[:username]
    else
      session[:idt1_username]
    end
  end
end
