require 'test_helper'

feature 'Can manage integrations' do
  before do
    visit login_path
    fill_in 'email_address', with: users(:user_one).email_address
    fill_in 'password', with: 'password'
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    Timecop.return
  end

  scenario 'integrations page exists' do
    visit integrations_path
    page.must_have_content 'Integrations & Add-on Services'
  end
end
