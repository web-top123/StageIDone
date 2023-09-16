require 'test_helper'

class Api::V2::EntriesControllerTest < ActionController::TestCase
  before do
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    @request.env['HTTP_AUTHORIZATION'] = 'Token abcdef'
  end

  # This test might be stupid
  test 'should be able to list entries' do
    get :index
    assert_response :success
    assert_equal JSON.parse(response.body).map{|e| e['hash_id']}, users(:user_one).entries.map{|e| e.hash_id},
      'Should return the correct list of entries'
  end

  test 'should be able to access single entry' do
    get :show, id: entries(:entry_one).hash_id
    assert_response :success
    assert_equal JSON.parse(response.body)['hash_id'], entries(:entry_one).hash_id,
      'Should return the entry in question'
  end

  test 'should not able to access entry belonging to other user & team' do
    get :show, id: entries(:entry_two).id
    assert_response 401
    assert_match 'not have access', JSON.parse(response.body)['error'],
      'Should return an error message about access'
  end

  test 'should be able to create entry' do
    assert_difference 'Entry.count', 1 do
      post :create, {body: 'Woop', team_id: 'my', occurred_on: Date.today}
    end
    assert_response :success
    assert_equal JSON.parse(response.body)['hash_id'], Entry.last.hash_id,
      'Should return the ID of the entry'
  end

  test 'should not be able to create entry into other team' do
    assert_difference 'Entry.count', 0 do
      post :create, {body: 'Woop', team_id: 'foo', occurred_on: Date.today}
    end
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should not be able to post without body' do
    assert_difference 'Entry.count', 0 do
      post :create, {team: 'my-team', occurred_on: Date.today}
    end
    assert_response 400
    assert_match /param is missing .* body/, JSON.parse(response.body)['error']
      'Should give error message explaining what\'s missing'
  end

  test 'should be able to update entry body' do
    put :update, {id: entries(:entry_one).hash_id, body: 'hejsan'}
    assert_response :success
    assert_match 'hejsan', JSON.parse(response.body)['body'],
      'Should have changed the body'
    assert_equal teams(:team_one).hash_id, JSON.parse(response.body)['team']['hash_id'],
      'Should not change the team'
    assert_equal entries(:entry_one).occurred_on, Date.parse(JSON.parse(response.body)['occurred_on']),
      'Should not change occurred_on'
  end

  test 'should be able to update entry team' do
    put :update, {id: entries(:entry_one).hash_id, team_id: 'bar'}
    assert_response :success
    assert_match entries(:entry_one).body, JSON.parse(response.body)['body'],
      'Should not change the body'
    assert_equal teams(:team_three).hash_id, JSON.parse(response.body)['team']['hash_id'],
      'Should change the team'
    assert_equal entries(:entry_one).occurred_on, Date.parse(JSON.parse(response.body)['occurred_on']),
      'Should not change occurred_on'
  end

  test 'should not be able to update entry with no access' do
    put :update, {id: entries(:entry_two).hash_id, body: 'hejsan'}
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should not be able to update entry to team without access' do
    put :update, {id: entries(:entry_one).hash_id, team_id: 'foo'}
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end

  test 'should be able to destroy entry' do
    assert_difference 'Entry.count', -1 do
      delete :destroy, {id: entries(:entry_one).hash_id}
    end
    assert_response :success
    assert_equal entries(:entry_one).hash_id, JSON.parse(response.body)['hash_id']
      'Returns the ID of the deleted entry'
  end

  test 'should not be able to destroy entry without access' do
    assert_difference 'Entry.count', 0 do
      delete :destroy, {id: entries(:entry_two).hash_id}
    end
    assert_response 401
    assert_match 'access', JSON.parse(response.body)['error']
      'Access error msg'
  end
end
