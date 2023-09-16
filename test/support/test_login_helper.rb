module TestLoginHelper
  def login_as(user)
    visit root_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: default_password
    click_on 'Login'
  end

  def logout
    visit settings_user_path
    click_on 'Logout'
  end
end
