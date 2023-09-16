require 'test_helper'

feature 'View team entries of selected date' do
  let(:april_01_2016) { Time.utc(2016,4,1,16,45,8) }
  let(:april_03_2016) { Time.utc(2016,4,3,16,45,8) }
  let(:april_04_2016) { Time.utc(2016,4,4,16,45,8) }

  # For testing entry ordering
  let(:april_02_2016_1800) { Time.utc(2016,4,2,18,0,0) }
  let(:april_02_2016_1805) { Time.utc(2016,4,2,18,5,0) }

  let(:dmy_april_01_2016) { april_01_2016.strftime('%Y-%m-%d') }
  let(:dmy_april_02_2016) { april_02_2016_1800.strftime('%Y-%m-%d') }
  let(:dmy_april_03_2016) { april_03_2016.strftime('%Y-%m-%d') }
  let(:dmy_april_04_2016) { april_04_2016.strftime('%Y-%m-%d') }

  let(:team_membership_u1_t4) { team_memberships(:user_one_team_four) }
  let(:team_membership_u2_t4) { team_memberships(:user_two_team_four) }
  let(:team_membership_u3_t1) { team_memberships(:user_three_team_one) }
  let(:team_membership_u1_personal) { team_memberships(:user_one_personal_team) }

  let(:this_team) { team_membership_u1_t4.team }
  let(:this_team_user_1) { team_membership_u1_t4.user }
  let(:this_team_user_2) { team_membership_u2_t4.user }

  let(:other_team) { team_membership_u3_t1.team }
  let(:other_team_user) { team_membership_u3_t1.user }

  let(:this_team_user_1_entry_april_01) { Entry.create!(
      body: "This team User 1 entry for April 01",
      user: this_team_user_1,
      team: this_team,
      status: 'done',
      occurred_on: april_01_2016) }
  let(:this_team_user_2_entry_april_01) { Entry.create!(
      body: "This team User 2 entry for April 01",
      user: this_team_user_2,
      team: this_team,
      status: 'blocked',
      occurred_on: april_01_2016) }
  let(:this_team_user_1_entry_april_03) { Entry.create!(
      body: "User 1 entry for April 03",
      user: this_team_user_1,
      team: this_team,
      status: 'goal',
      occurred_on: april_03_2016) }
  let(:this_team_user_1_personal_entry_april_03) { Entry.create!(
      body: "User 1 personal entry for April 03",
      user: this_team_user_1,
      team: teams(:user_one_personal),
      status: 'goal',
      occurred_on: april_03_2016) }
  let(:other_team_user_entry_april_03) { Entry.create!(
      body: "Other team user entry for April 03",
      user: other_team_user,
      team: other_team,
      status: 'done',
      occurred_on: april_03_2016) }

  let(:this_team_user_1_entry_april_02_1800) { Entry.create!(
      body: "This team User 1 entry for April 02 at 1800",
      user: this_team_user_1,
      team: this_team,
      status: 'done',
      created_at: april_02_2016_1800,
      occurred_on: april_02_2016_1800) }
  let(:this_team_user_1_entry_april_02_1805) { Entry.create!(
      body: "This team User 1 entry for April 02 at 1805",
      user: this_team_user_1,
      team: this_team,
      status: 'done',
      created_at: april_02_2016_1805,
      occurred_on: april_02_2016_1805) }

  before do
    travel_to april_04_2016

    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    visit root_path
    fill_in 'email_address', with: this_team_user_1.email_address
    fill_in 'password', with: default_password
    click_on 'Login'

    # Create entries for April 01
    this_team_user_1_entry_april_01
    this_team_user_2_entry_april_01

    # Create entries for April 02; used to testing entries ordering
    this_team_user_1_entry_april_02_1800
    this_team_user_1_entry_april_02_1805

    # Create entries for April 03
    this_team_user_1_entry_april_03
    this_team_user_1_personal_entry_april_03
    other_team_user_entry_april_03
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    travel_back
  end

  scenario "Show no entries if no date selected" do
    visit calendar_team_path(this_team)
    assert_no_selector('div#entries > h2')
  end

  scenario "Show 'None' if date selected has no entries", js: true do
    visit calendar_team_path(this_team)
    find("div.card[data-value=\"#{dmy_april_04_2016}\"] > div.indicator").click
    assert_selector('div#entries',
         text: "Monday, April 4 None")
  end

  scenario "Show entries for this team if date selected", js: true  do
    visit calendar_team_path(this_team)
    find("div.card[data-value=\"#{dmy_april_01_2016}\"] > div.indicator").click
    assert_selector('div#entries',
         text: "Friday, April 1 " +
               "T This team User 1 entry for April 01 " +
               "S This team User 2 entry for April 01")
  end

  scenario "Show entries for this team ONLY excluding team users' personal logs other team entries if date selected", js: true do
    visit calendar_team_path(this_team)
    find("div.card[data-value=\"#{dmy_april_03_2016}\"] > div.indicator").click
    assert_selector('div#entries',
         text: "Sunday, April 3 " +
               "T User 1 entry for April 03")
  end

  scenario "Show entries for this team ONLY excluding team users' personal logs other team entries if date selected", js: true do
    visit calendar_team_path(this_team)
    find("div.card[data-value=\"#{dmy_april_02_2016}\"] > div.indicator").click
    assert_selector('div#entries',
         text: "Saturday, April 2 " +
               "T This team User 1 entry for April 02 at 1800 " +
                 "This team User 1 entry for April 02 at 1805")
  end
end
