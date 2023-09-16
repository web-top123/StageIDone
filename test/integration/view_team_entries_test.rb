require 'test_helper'

feature 'View team entries' do
  let(:april_01_2016) { Time.utc(2016,4,1,16,45,8) }
  let(:april_02_2016) { Time.utc(2016,4,2,16,45,8) }
  let(:april_03_2016) { Time.utc(2016,4,3,16,45,8) }
  let(:april_04_2016) { Time.utc(2016,4,4,16,45,8) }
  let(:april_05_2016) { Time.utc(2016,4,5,16,45,8) }

  let(:user) { users(:user_one) }
  let(:team) { teams(:team_one) }
  let(:entry_april_01) { Entry.new(body: "Entry for April 01", team: team, occurred_on: april_01_2016)}
  let(:entry_april_03) { Entry.new(body: "Entry for April 03", team: team, occurred_on: april_03_2016)}
  let(:teri) { users(:user_three) }
  let(:teri_membership) { team_memberships(:user_three_team_one) }

  let(:remove_teri_from_team_on_april_04) do
    travel_to april_04_2016

    visit team_team_memberships_path(team)
    page.assert_selector('a', text: 'Teri Wilson')
    find("a[href=\"/t/#{team.hash_id}/memberships/#{teri_membership.id}\"]", text: 'Remove from team').click
    page.assert_no_selector('a', text: 'Teri Wilson')    
  end

  let(:soft_delete_teri_on_april_04) do
    travel_to april_04_2016
    teri.destroy
  end

  before do
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    visit root_path
    user.entries << entry_april_01
    teri.entries << entry_april_03
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: default_password
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    travel_back
  end

  ###########################
  ## Viewing team entries ###
  ###########################
  scenario "visting the team entries page on April 01 shows the April 01 entry, and we haven't heard from Teri" do
    travel_to april_01_2016
    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Friday, April 1'
    page.must_have_content 'Entry for April 01'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 02 shows no entries, and we haven't heard from Teri" do
    travel_to april_02_2016
    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Saturday, April 2'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      page.assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 03 shows Teri's entries" do
    travel_to april_03_2016
    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Sunday, April 3'
    page.must_have_content 'Entry for April 03'
    page.assert_no_selector('.day-users')
  end

  ####################################################
  ## Viewing team entries with removed team member ###
  ####################################################
  scenario "visting the team entries page on April 02 after Teri was removed April 04" do
    remove_teri_from_team_on_april_04
    travel_to april_02_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Saturday, April 2'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      page.assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 03 after Teri was removed April 04" do
    remove_teri_from_team_on_april_04
    travel_to april_03_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Sunday, April 3'
    page.must_have_content 'Entry for April 03'
    page.assert_no_selector('.day-users')
  end

  scenario "visting the team entries page on April 04 after Teri was removed April 04" do
    remove_teri_from_team_on_april_04
    travel_to april_04_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Monday, April 4'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      page.assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 05 after Teri was removed April 04" do
    remove_teri_from_team_on_april_04
    travel_to april_05_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Tuesday, April 5'
    page.assert_no_selector('.day-users')
  end


  #########################################################
  ## Viewing team entries with soft deleted team member ###
  #########################################################
  scenario "visting the team entries page on April 02 after Teri was soft deleted April 04" do
    soft_delete_teri_on_april_04
    travel_to april_02_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Saturday, April 2'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      page.assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 03 after Teri was soft deleted April 04" do
    soft_delete_teri_on_april_04
    travel_to april_03_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Sunday, April 3'
    page.must_have_content 'Entry for April 03'
    page.assert_no_selector('.day-users')
  end

  scenario "visting the team entries page on April 04 after Teri was soft deleted April 04" do
    soft_delete_teri_on_april_04
    travel_to april_04_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Monday, April 4'
    within '.day-users' do
      page.must_have_content "We haven't heard from"
      page.assert_selector('div.portrait', text: 'T')
    end
  end

  scenario "visting the team entries page on April 05 after Teri was soft deleted April 04" do
    soft_delete_teri_on_april_04
    travel_to april_05_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Tuesday, April 5'
    page.assert_no_selector('.day-users')
  end

  ######################################################################
  ## Viewing team entries with removed then soft deleted team member ###
  ######################################################################
  scenario "visting the team entries page on April 03 after Teri was removed and soft deleted April 04" do
    remove_teri_from_team_on_april_04
    soft_delete_teri_on_april_04
    travel_to april_03_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Sunday, April 3'
    page.must_have_content 'Entry for April 03'
    page.assert_no_selector('.day-users')
  end

  scenario "visting the team entries page on April 05 after Teri was removed and soft deleted April 04" do
    remove_teri_from_team_on_april_04
    soft_delete_teri_on_april_04
    travel_to april_05_2016

    visit team_path(team)
    page.must_have_content 'My Team'
    page.must_have_content 'Tuesday, April 5'
    page.assert_no_selector('.day-users')
  end
end
