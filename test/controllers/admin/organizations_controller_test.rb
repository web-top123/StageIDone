require 'test_helper'

class Admin::OrganizationsControllerTest < ActionController::TestCase
  test "can list organizations" do
    get :index
    assert_response :success
    assert_match 'My Org', response.body
  end

  test "can show organization" do
    get :show, id: 'myorg'
    assert_response :success
    assert_match 'My Org', response.body
  end
end
