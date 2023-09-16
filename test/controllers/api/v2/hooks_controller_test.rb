require 'test_helper'

class Api::V2::HooksControllerTest < ActionController::TestCase
  before do
    @request.env['HTTP_AUTHORIZATION'] = 'Token abcdef'
  end

  # This test might be stupid
  test 'should be able to list entries' do
    get :index
    assert_response :success
    assert_equal JSON.parse(response.body).map{|h| h['id']}, users(:user_one).hooks.map{|h| h.id},
      'Should return the correct list of entries'
  end

  test 'should be able to access single hook' do
    get :show, id: hooks(:hook_one).id
    assert_response :success
    assert_equal JSON.parse(response.body)['id'], hooks(:hook_one).id,
      'Should return the hook in question'
  end

  test 'should not able to access hook belonging to other user & team' do
    get :show, id: hooks(:hook_three).id
    assert_response 401
    assert_match 'not have access', JSON.parse(response.body)['error'],
      'Should return an error message about access'
  end

  test 'should be able to create hook' do
    assert_difference 'Hook.count', 1 do
      post :create, {target_url: 'https://idonethis.com/hooks/123', team_id: 'my'}
    end
    assert_response :success
    assert_equal JSON.parse(response.body)['id'], Hook.last.id,
      'Should return the ID of the hook'
  end

  test 'should not be able to create hook into other team' do
    assert_difference 'Hook.count', 0 do
      post :create, {target_url: 'https://idonethis.com/hooks/123', team_id: 'foo'}
    end
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should not be able to post without url' do
    assert_difference 'Hook.count', 0 do
      post :create, {team_id: 'my'}
    end
    assert_response 400
    assert_match /param is missing .* target_url/, JSON.parse(response.body)['error']
      'Should give error message explaining what\'s missing'
  end

  test 'should be able to update hook url' do
    put :update, {id: hooks(:hook_one).id, target_url: 'http://hejsan.se'}
    assert_response :success
    assert_match 'http://hejsan.se', JSON.parse(response.body)['target_url'],
      'Should have changed the url'
    assert_equal teams(:team_one).hash_id, JSON.parse(response.body)['team']['hash_id'],
      'Should not change the team'
  end

  test 'should be able to update hook team' do
    put :update, {id: hooks(:hook_one).id, team_id: 'bar'}
    assert_response :success
    assert_match hooks(:hook_one).target_url, JSON.parse(response.body)['target_url'],
      'Should not change the body'
    assert_equal teams(:team_three).hash_id, JSON.parse(response.body)['team']['hash_id'],
      'Should change the team'
  end

  test 'should not be able to update hook with no access' do
    put :update, {id: hooks(:hook_three).id, target_url: 'http://hejsan.se'}
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should not be able to update hook to team without access' do
    put :update, {id: hooks(:hook_one).id, team_id: 'foo'}
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should be able to destroy hook' do
    assert_difference 'Hook.count', -1 do
      delete :destroy, {id: hooks(:hook_one).id}
    end
    assert_response :success
    assert_equal hooks(:hook_one).id, JSON.parse(response.body)['id']
      'Returns the ID of the deleted hook'
  end

  test 'should not be able to destroy hook without access' do
    assert_difference 'Hook.count', 0 do
      delete :destroy, {id: hooks(:hook_three).id}
    end
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end
end
