require 'test_helper'

class Api::V2::TeamsControllerTest < ActionController::TestCase
  before do
    @request.env['HTTP_AUTHORIZATION'] = 'Token abcdef'
  end

  # This test might be stupid
  test 'should be able to list entries' do
    get :index
    assert_response :success
    assert_equal JSON.parse(response.body).map{|t| t['hash_id']}, users(:user_one).active_teams.map{|t| t.hash_id},
      'Should return the correct list of teams'
  end

  test 'should be able to view team by slug' do
    get :show, {id: teams(:team_one).hash_id}
    assert_response :success
    assert_equal teams(:team_one).hash_id, JSON.parse(response.body)['hash_id'],
      'Should return the correct id'
  end

  test 'should be able to view team by id' do
    get :show, {id: teams(:team_one).id}
    assert_response 401
  end

  test 'should not be able to view team without access' do
    get :show, {id: teams(:team_two).hash_id}
    assert_response 401
    assert_match /access/, JSON.parse(response.body)['error'],
      'Error msg should mention access'
  end
end
