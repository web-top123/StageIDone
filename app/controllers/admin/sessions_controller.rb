class Admin::SessionsController < ApplicationController
  skip_after_action :verify_authorized
  layout 'modal'

  def new
  end

  def create
    info = request.env['omniauth.auth']['info']
    if info['email'].split('@',2).last == 'idonethis.com'
      @user = AdminUser.find_or_create_from_oauth(info)
      session[:admin_user_id] = @user.id
      redirect_to admin_dashboard_path
    else
      flash[:alert] = 'You are not authorized to access admin controls'
      redirect_to root_path
    end
  end
end
