class Admin::UsersController < Admin::ApplicationController
  def index
    if params[:filter_field].present? &&
       (params[:filter_field].downcase != 'all') &&
       User.with_deleted.filter_fields.include?(params[:filter_field].downcase)

      @users = User.with_deleted.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).page(params[:page])
      @scope_count = User.with_deleted.alphabetically.advanced_search(params[:filter_field].to_sym => params[:filter_value]).size
      @filter_params = params.slice(:filter_field, :filter_value)

      if @users.size == 1
        redirect_to [:admin, @users.first]
        return
      end
    else
      @scope_count = User.with_deleted.alphabetically.count
      @users = User.with_deleted.alphabetically.page(params[:page])
    end
  end

  def show
    @filter_params = params.slice(:filter_field, :filter_value)
    @user = User.with_deleted.find_by(hash_id: params[:id])
  end

  def update
    @user = User.find_by(hash_id: params[:id])
    @user.update_attributes(user_params)
    redirect_to [:admin, @user]
  end

  def log_in_as_user
    @user = User.find_by(hash_id: params[:id])
    auto_login(@user)
    redirect_to root_path
  end

  def restore
    @user = User.only_deleted.find_by(hash_id: params[:id])
    @user.restore(recursive: true)
    redirect_to [:admin, @user], notice: "#{@user.email_address} has been restored."
  end

  def destroy
    @user = User.find_by(hash_id: params[:id])
    @user.destroy
    redirect_to [:admin, @user], notice: "#{@user.email_address} has been soft deleted."
  end

  def hard_delete
    User.transaction do
      @user = User.with_deleted.find_by(hash_id: params[:id])
      @user.personal_teams.each(&:destroy)
      @user.really_destroy!
      redirect_to [:admin, :users], notice: "#{@user.email_address} has been permanently deleted."
    end
  end

  def send_reset
    @user = User.find_by(hash_id: params[:id])
    UserMailer.reset_password(@user).deliver_now
    # PasswordEmailWorker.perform_async(@user.id)
    redirect_to [:admin, @user]
  end

  def verify_email
    @user = User.find_by(hash_id: params[:id])
    @user.verify!
    redirect_to [:admin, @user]
  end

  private

  def user_params
    params.require(:user).permit(
      :email_address,
      :full_name,
      :time_zone,
      :phone_number,
      :go_by_name,
      :show_personal_team
    )
  end
end