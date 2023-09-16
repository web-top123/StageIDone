class Api::V2::UsersController < Api::V2::BaseController

  # GET
  # http://localhost:3000//api/v2/users/request_reset?api_token=db4de0d2886f486f2a2d24e0f5cfed305740eacd&email_address=hardik@gmail.com
  def request_reset
    @email_address = params[:email_address]
    @user = User.find_by(email_address: @email_address)
    if @email_address && @user
      # PasswordEmailWorker.perform_async(@user.id) 
      UserMailer.reset_password(@user).deliver_now
      render json: { success: "We sent an email to #{@email_address} with a link that will allow you to reset your password." }, status: 200
    else
      render json: { errors: "Invalid email id" }, status: 422
    end
  end 

  # POST
  # http://localhost:3000/api/v2/users/2/personalize?api_token=dc1c3f51a091278e98cf377b082fcfa36c2066a
  # in body ,portrait = codebase64ofimages
  def personalize
    @user = @current_user
    io = StringIO.new(Base64.decode64(params[:portrait]))
    def io.original_filename; "pic.jpg"; end
    @user.update_attributes portrait: io
    render json: { success: "Profile pic updated successfully." }, status: 200
  end
end
