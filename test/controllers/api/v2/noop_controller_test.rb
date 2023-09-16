require 'test_helper'

class Api::V2::NoopControllerTest < ActionController::TestCase
  test 'accessing without token produces error' do
    get :index
    assert_response 401, 'Should respond with 401, not authorized'
    assert_equal JSON.parse(response.body), {'error' => 'Invalid API Authentication'},
      'Body should have an error message'
  end
  test 'accessing with token works' do
    @request.env['HTTP_AUTHORIZATION'] = 'Token abcdef'
    get :index
    assert_response :success
    assert_equal JSON.parse(response.body)['email_address'], 'test@idonethis.com',
      'Should return the correct user (from fixtures)'
  end
end
