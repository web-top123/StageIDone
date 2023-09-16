require 'test_helper'

describe TagsController do
  before do
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    login_user(users(:user_one))
  end

  test '404 on tag view for team where tag does not exist' do
    assert_raises(ActionController::RoutingError) do
      get :show, id: 'testing', team_id: teams(:team_one).hash_id
    end
  end

  test '404 on tag view for org where tag does not exist' do
    assert_raises(ActionController::RoutingError) do
      get :show, id: 'testing', organization_id: organizations(:org_one)
    end
  end

  test 'can view tag for team' do
    Entry.create(user: users(:user_one), team: teams(:team_one), body: 'whaddap cool #testing #tags', occurred_on: Date.current, status: 'done')
    get :show, id: 'testing', team_id: teams(:team_one).hash_id
    assert_response :success
    assert_match 'whaddap', response.body
  end

  test 'can view tag for org' do
    Entry.create(user: users(:user_one), team: teams(:team_one), body: 'whaddap cool #testing #tags', occurred_on: Date.current, status: 'done')
    get :show, id: 'testing', organization_id: organizations(:org_one)
    assert_response :success
    assert_match 'whaddap', response.body
  end
end
