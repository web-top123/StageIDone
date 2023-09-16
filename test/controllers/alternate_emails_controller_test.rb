require 'test_helper'

class AlternateEmailsControllerTest < ActionController::TestCase
  let(:alternate_email) { alternate_emails(:unverified) }

  setup do
    login_user(users(:user_one))
  end

  test "should create alternate_email" do
    assert_difference('AlternateEmail.count') do
      post :create, alternate_email: { email_address: 'fred@flinstone.com' }
    end

    assert_response :success
    assert_template partial: '_list'
  end

  test "should verify alternate_email" do
    get :verify, verification_code: alternate_email.verification_code

    alternate_email.reload
    assert_nil alternate_email.verification_code
    assert_not_nil alternate_email.verified_at
    assert_redirected_to settings_user_url
  end

  test "should destroy alternate_email" do
    assert_difference('AlternateEmail.count', -1) do
      delete :destroy, id: alternate_email
    end

    assert_response :success
    assert_template partial: '_list'
  end
end
