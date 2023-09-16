class Api::V2::BaseController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  before_filter :authenticate , except: :request_reset
  around_filter :user_time_zone, if: "@current_user.present?"

  def authenticate
    error!('Invalid API Authentication', 401) and return unless authenticated?
  end

  private

  def user_time_zone(&block)
    Time.use_zone(@current_user.time_zone, &block)
  end

  def authenticated?
    if api_token
      @current_user = User.find_by(api_token: api_token)
    elsif valid_doorkeeper_token?
      @current_user = User.find(doorkeeper_token.resource_owner_id)
    end
    return !@current_user.nil?
  end

  # Look for authentication in the request header and then a param called api_token.
  def api_token
    return request.headers['Authorization'][/Token (.*)/, 1] if request.headers['Authorization']
    return params[:api_token] if params[:api_token]
    nil
  end

  def parameter_missing(e)
    error!(e.message, 400)
  end

  def error!(msg, status)
    render json: {error: msg}, status: status
  end
end