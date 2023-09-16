class Api::V2::NoopController < Api::V2::BaseController

  def index
    render json: @current_user.as_json(only: [:hash_id, :email_address, :full_name])
  end

end