require 'test_helper'

feature 'Can manage teams' do

  let (:user_1) { users(:user_one) }
  let (:team_1) { teams(:team_one) }
  let (:team_2) { teams(:team_two) }
  let (:team_5) { teams(:team_five) }

  let(:team_membership_1) { team_memberships(:user_one_team_one) }

  before do
    travel_to(Time.utc(2016,4,1,16,45,8))
    visit root_path
    fill_in 'email_address', with: user_1.email_address
    fill_in 'password', with: 'password'
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    travel_back
  end

  scenario 'settings page and email throttling message' do
    # Before throttling, there's no message
    visit settings_team_path(id: team_membership_1.team.hash_id)
    page.wont_have_content 'Inactivity caused your emails to decrease to send once a week'
    page.wont_have_link("back", text: unthrottle_emails_team_team_membership_path({ team_id: team_membership_1.team.hash_id, id: team_membership_1.id }))

    # After throttling, there should be a message
    team_membership_1.throttle_email_days
    visit settings_team_path(id: team_membership_1.team.hash_id)
    page.must_have_content 'Inactivity caused your emails to decrease to send once a week'
    page.must_have_link('back', href: unthrottle_emails_team_team_membership_path({ team_id: team_membership_1.team.hash_id, id: team_membership_1.id }))
  end

  describe "when user's team_1, team_3 belongs to diffferent organizations" do
    scenario 'user get 403 in attempt to access #show with team id that differs from logged in' do
      visit team_path(team_5.hash_id)
      assert_equal 403, page.status_code
      assert page.text.match(/You are logged in as test@idonethis.com but you are trying to access another organization/)
    end
  end

  describe "when user's team_1, team_2 belongs to same organization and user tries to access team_2 while logged into team_1" do
    scenario 'get join message when attempt to access #show with team id that differs from logged in' do
      visit team_path(team_2.hash_id)
      assert_equal 200, page.status_code
      assert page.text.match(/My Org Foo Team/)
      assert page.text.match(/not a member of Foo Team so you can't add entries here unless you join/)
    end
  end
end
