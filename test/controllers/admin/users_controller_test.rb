require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  test "can list users" do
    get :index
    assert_response :success
    assert_match 'Test User', response.body
    assert_match 'Second User', response.body
  end

  test "can show user" do
    get :show, id: users(:user_one).hash_id
    assert_response :success
    assert_match 'Test User', response.body
  end
end
