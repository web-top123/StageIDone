require 'test_helper'

feature 'Can react to entries' do
  let (:april_01_2016) { Time.utc(2016,4,1,16,45,8) }

  before do
    ActionMailer::Base.deliveries.clear
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    travel_to april_01_2016
    visit login_path
    fill_in 'email_address', with: users(:user_one).email_address
    fill_in 'password', with: 'password'
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    travel_back
  end

  scenario 'user 2 is able to like user 1s post', js: true do
    Entry.create(team: teams(:team_four), user: users(:user_two), body: 'Test Entry', occurred_on: Date.current)
    visit team_path(teams(:team_four))
    page.must_have_content 'Test Entry'
    assert_difference 'Reaction.count', 1 do
      find('a[data-action="toggleLike"]').click
      sleep 1
    end
  end

  # Can't write an integration test for commenting because we can't click enter
  # with capybara and there's no button to save the comment
end
