class Api::V2::SessionsController < ActionController::Base
  
  # POST
  # http://localhost:3000/api/v2/login?email_address=pooja@gmail.com&crypted_password=123456
  def create
    user_password = params[:crypted_password]
    user_email = params[:email_address]
    user = user_email.present? && User.find_by(email_address: user_email) 
    if @user = login(params[:email_address], params[:crypted_password], true)
      render formats: :json
    else
      render json: { errors: "Invalid email or password" }, status: 422
    end
  end

  # POST
  # http://localhost:3000/api/v2/gmail_login?email_address=pooja@gmail.com&crypted_password=123456
  def gmail_login
    user_email = params[:email_address]
    @user = user_email.present? && User.find_by(email_address: user_email)
    @auth_gmail_user = @user.authentications.where(:provider => "google").first
    if @auth_gmail_user.present?
      render formats: :json
    else
      render json: { errors: "Invalid email or password" }, status: 422
    end
  end

  # POST
  # http://localhost:3000/api/v2/logout?email_address=pooja@gmail.com&crypted_password=123456
  def destroy
    logout
    render json: { success: "You logout succesfully." }, status: 200
  end
end 