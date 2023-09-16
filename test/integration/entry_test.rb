require 'test_helper'

feature 'Can create entries' do
  before do
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    Timecop.freeze(Time.utc(2016,4,1,16,45,8))
    visit root_path
    fill_in 'email_address', with: users(:user_one).email_address
    fill_in 'password', with: 'password'
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    Timecop.return
  end

  scenario 'team page exists and shows correct date' do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    page.must_have_content 'Friday, April 1'
  end

  scenario 'it is possible to post a done', js: true do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    within 'form#new_entry' do
      fill_in 'entry[body]', with: 'Testing the dones #testing!'
      page.must_have_content 'Press Enter'
      find('.entry-hint a').click
    end
    page.must_have_content 'Testing the dones #testing!'
    assert_equal find('textarea[name="entry[body]"]').value.blank?, true
    assert_equal Entry.last.status, 'done'
    assert_equal Entry.last.occurred_on, Date.new(2016, 4, 1)
    assert_equal Entry.last.body, 'Testing the dones #testing!'
  end

  scenario 'it is possible to post a goal via text', js: true do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    within 'form#new_entry' do
      fill_in 'entry[body]', with: '[]this is a goal with a link to https://google.com'
      page.must_have_content 'Press Enter'
      find('.entry-hint a').click
    end
    page.must_have_content 'this is a goal'
    assert_equal find('textarea[name="entry[body]"]').value.blank?, true
    assert_equal Entry.last.status, 'goal'
    assert_equal Entry.last.occurred_on, Date.new(2016, 4, 1)
    assert_equal Entry.last.body, 'this is a goal with a link to https://google.com'
  end

  scenario 'it is possible to post a blocker via clicking', js: true do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    within 'form#new_entry' do
      find('.status-current div').click
      find('.status-options li[data-value="blocked"]').click
      fill_in 'entry[body]', with: 'this is a blocker mentioning @Second User'
      page.must_have_content 'Press Enter'
      find('.entry-hint a').click
    end
    page.must_have_content 'this is a blocker'
    assert_equal find('textarea[name="entry[body]"]').value.blank?, true
    assert_equal Entry.last.status, 'blocked'
    assert_equal Entry.last.occurred_on, Date.new(2016, 4, 1)
    assert_equal Entry.last.body, 'this is a blocker mentioning @Second User'
  end

  scenario 'it is possible to post a done in the past', js: true do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    find('a[data-bind="datePicker"]').click
    find('a[data-action="goToPreviousMonth"]', text: '<').click
    find('a[data-action="pickDate"]', text: '31').click
    within 'form#new_entry' do
      fill_in 'entry[body]', with: 'Testing the dones!'
      page.must_have_content 'Press Enter'
      find('.entry-hint a').click
    end
    page.must_have_content 'Testing the dones!'
    assert_equal find('textarea[name="entry[body]"]').value.blank?, true
    assert_equal Entry.last.status, 'done'
    assert_equal Entry.last.occurred_on, Date.new(2016, 3, 31)
    assert_equal Entry.last.created_at, Time.current
    assert_equal Entry.last.body, 'Testing the dones!'
  end

  scenario 'it is possible to post a done in the future', js: true do
    visit team_path(teams(:team_one))
    page.must_have_content 'My Team'
    find('a[data-bind="datePicker"]').click
    find('a[data-action="pickDate"]', text: '10').click
    within 'form#new_entry' do
      fill_in 'entry[body]', with: 'Testing the dones!'
      page.must_have_content 'Press Enter'
      find('.entry-hint a').click
    end
    page.must_have_content 'Testing the dones!'
    assert_equal find('textarea[name="entry[body]"]').value.blank?, true
    assert_equal Entry.last.status, 'done'
    assert_equal Entry.last.occurred_on, Date.new(2016, 4, 10)
    assert_equal Entry.last.created_at, Time.current
    assert_equal Entry.last.body, 'Testing the dones!'
  end
end
