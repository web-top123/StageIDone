require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  setup do
    login_user(users(:user_one))
  end

  test "should get index" do
    get :index
    assert_response :success
  end

end
