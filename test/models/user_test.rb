require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'set_sorting_name with single name' do
    user = users(:user_one)
    user.full_name = 'John'
    user.valid? # Should call set_sorting_name
    assert_equal 'John', user.sorting_name
  end
  test 'set_sorting_name with double name' do
    user = users(:user_one)
    user.full_name = 'John Smith'
    user.valid? # Should call set_sorting_name
    assert_equal 'Smith, John', user.sorting_name
  end
  test 'set_sorting_name with triple name' do
    user = users(:user_one)
    user.full_name = 'John Deere Smith'
    user.valid? # Should call set_sorting_name
    assert_equal 'Smith, John Deere', user.sorting_name
  end
  test 'first_name_and_last_initial with single name' do
    user = users(:user_one)
    user.full_name = 'John'
    assert_equal 'John', user.first_name_and_last_initial
  end
  test 'first_name_and_last_initial with double name' do
    user = users(:user_one)
    user.full_name = 'John Smith'
    assert_equal 'John S.', user.first_name_and_last_initial
  end
  test 'first_name_and_last_initial with triple name' do
    user = users(:user_one)
    user.full_name = 'John Deere Smith'
    assert_equal 'John Deere S.', user.first_name_and_last_initial
  end
  test 'full_name_initials with single name' do
    user = users(:user_one)
    user.full_name = 'John'
    assert_equal 'J', user.full_name_initials
  end
  test 'full_name_initials with double name' do
    user = users(:user_one)
    user.full_name = 'John Smith'
    assert_equal 'JS', user.full_name_initials
  end
  test 'full_name_initials with triple name' do
    user = users(:user_one)
    user.full_name = 'John Deere Smith'
    assert_equal 'JDS', user.full_name_initials
  end
  test 'token revoke' do
    user = users(:user_one)
    old_token = user.api_token
    user.reset_api_token!
    assert_not_equal old_token, user.api_token
  end
  test 'time zone is not changed in validation callback if already set' do
    user = users(:user_one)
    user.valid?
    assert_equal 'Berlin', user.time_zone    
  end
  test 'time zone is set to default in validation callback if empty string' do
    user = users(:user_one)
    user.time_zone = ""
    user.valid?
    assert_equal 'Pacific Time (US & Canada)', user.time_zone    
  end
  test 'time zone is set to default in validation callback if nil' do
    user = users(:user_one)
    user.time_zone = nil
    user.valid?
    assert_equal 'Pacific Time (US & Canada)', user.time_zone    
  end
end
