require 'test_helper'

class Admin::AppSettingsControllerTest < ActionController::TestCase
  before do
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}')
  end

  test "can view app settings" do
    get :show
    assert_response :success
    assert_match 'App Settings', response.body
    assert_match 'Don&#39;t change', response.body
  end

  test "can update app settings" do
    put :update, {app_setting: {tiny_monthly_plan_id: 'VerneTroyer'}}
    assert_response 302
    assert_equal 'VerneTroyer', AppSetting.current.tiny_monthly_plan_id
  end

  test "updating with invalid data should redirect to show" do
    put :update, {app_setting: {tiny_monthly_plan_id: ''}}
    assert_response 200
    assert_match 'App Settings', response.body
  end
end
