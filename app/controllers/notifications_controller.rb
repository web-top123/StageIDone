class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @pending_invitations = current_user.pending_invitations
    
    @notifications = current_user.
      notifications.
      eager_load(entry: :team).
      order(created_at: :desc)

    @all_notifications = params[:all]
    limit = @all_notifications ? 10000 : 10
    
    @archived_notifications = current_user.
      archived_notifications.
      eager_load(entry: :team).
      order(updated_at: :desc).
      limit(limit)
    

    @hidden_archived_notifications_count = 
      current_user.archived_notifications.count - @archived_notifications.count

    authorize :invitation
  end

  def clear
    current_user.clear_notifications!
    
    redirect_to action: :index

    authorize :notification
  end

  def destroy
    notification = current_user.notifications.find_by_id(params[:id])
    notification.archive! unless notification.nil?

    render json:{status:'done'}

    authorize :notification
  end

  def reload_archived
    
    @all_notifications = params[:all]  

    limit = @all_notifications ? 10000 : 10
    
    @archived_notifications = current_user.
      archived_notifications.
      eager_load(entry: :team).
      order(updated_at: :desc).
      limit(limit)

    @hidden_archived_notifications_count = 
      current_user.archived_notifications.count - @archived_notifications.count

    render :partial => "archived_notifications"

    authorize :notification
  end
end
