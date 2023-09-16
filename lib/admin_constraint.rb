class AdminConstraint
  def matches?(request)
    if Rails.env.production?
      return false unless request.session[:admin_user_id]
      admin = AdminUser.find_by(id: request.session[:admin_user_id])
      admin.present?
    else
      true
    end
  end
end
