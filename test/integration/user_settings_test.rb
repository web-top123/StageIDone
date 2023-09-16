require 'test_helper'

feature 'Can manage user settings' do
  before do
    Timecop.freeze(Time.utc(2016,4,1,16,45,8))
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

  scenario 'settings page exists' do
    visit settings_user_path
    user = users(:user_one)
    page.must_have_content 'Account settings'
    assert_equal user.full_name, find('input[name="user[full_name]"]').value
    assert_equal user.email_address, find('input[name="user[email_address]"]').value
  end

  scenario 'can edit user full_name from user settings page' do
    visit settings_user_path
    user = users(:user_one)
    within "form#edit-user-details" do
      fill_in 'user[full_name]', with: 'Benji Franklin'
      click_on 'Save Changes'
    end
    assert_equal User.find_by(email_address: user.email_address).full_name, 'Benji Franklin'
  end

  scenario 'can revoke user api token from user settings page' do
    visit settings_user_path
    user = users(:user_one)
    old_token= find_field('api_token').value
    click_on 'Reset'
    assert_not_equal find_field('api_token').value, old_token
  end
end
