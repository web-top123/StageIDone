require 'test_helper'

describe ReactionsController do
  before do
    login_user(users(:user_one))
  end

  test 'can create a comment' do
    entry = Entry.create(team: teams(:team_four), user: users(:user_two), body: 'Test Entry', occurred_on: Date.current, status: 'done')

    assert_difference 'Reaction.count', 1 do
      post :create, entry_id: entry.hash_id, comment_body: 'wow this is cool!'
    end
    assert_match 'wow this is cool!', response.body
  end
end
