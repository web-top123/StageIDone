class ErrorsController < ApplicationController
  skip_after_action :verify_authorized
  layout 'error'

  def todo
    Raven.capture_message "TODO request for '#{ params[:f] }'"
    render status: 404
  end

  def incorrect_organization
    render status: 403
  end

  def not_found
    render status: 404
  end

  def internal_server_error
    render status: 500
  end
end
