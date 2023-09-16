require 'test_helper'

feature 'Can Log in' do
  scenario 'login page exists' do
    visit login_path
    page.must_have_content 'Log in'
  end

  scenario 'logging in for first time with new user that has an org should not be onboarded' do
    visit login_path
    fill_in 'email_address', with: 'test@idonethis.com'
    fill_in 'password', with: 'password'
    click_on 'Login'
    page.must_have_content 'Account settings'
  end

  scenario 'logging in for first time with old user takes me through onboarding' do
    visit login_path
    fill_in 'email_address', with: 'test+two@idonethis.com'
    fill_in 'password', with: 'password'
    click_on 'Login'
    page.must_have_content 'Welcome to I Done This'
    click_on 'Continue'
    page.must_have_content 'New icons and blockers'
    click_on 'Got it'
    page.must_have_content 'Account settings'
  end
end
