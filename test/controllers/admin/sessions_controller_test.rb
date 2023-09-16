require 'test_helper'

class Admin::SessionsControllerTest < ActionController::TestCase
  test 'can see login page' do
    get :new
    assert_response :success
    assert_match 'Sign in', response.body
  end

  test 'can log in' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
        'provider' => 'google',
        'uid' => '1234512345',
        'info' => {'email' => 'testing@idonethis.com', 'name' => 'test', 'image' => ''}
    })
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google]

    get :create
    assert_redirected_to admin_dashboard_path
  end

  test 'can not log in' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
        'provider' => 'google',
        'uid' => '1234512345',
        'info' => {'email' => 'testing@attacker.com', 'name' => 'test', 'image' => ''}
    })
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google]

    get :create
    assert_redirected_to root_path
  end
end
