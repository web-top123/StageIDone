require 'test_helper'

class IntegrationUserTest < ActiveSupport::TestCase
  let(:user_1) { FactoryGirl.create(:user) }
  let(:user_2) { FactoryGirl.create(:user) }
  let(:omniauth_auth) {
    {
      'uid' => 'U28UKG598',
      'credentials' => {
        'token' => 'xoxp-123456789',
        'expires' => false,
      },
      'info' => {
        'user' => 'tom',
        'team' => 'team tom',
        'team_id' => 'T0FR0A8HH',
      },
    }
  }

  test 'create slack integration user' do
    assert_difference 'IntegrationUser.all.count', 1 do
      IntegrationUser.new_from_slack_oauth(
        user_1,
        omniauth_auth).save!
    end
    iuser = IntegrationUser.find_by(oauth_uid: omniauth_auth['uid'])
    assert_equal({ 'slack_user_name' => 'tom', 'slack_team_name' => 'team tom', 'slack_team_id' => 'T0FR0A8HH' },
                 iuser.meta_data)
  end

  test 'fail to create a duplicate slack integration user' do
    assert_difference 'IntegrationUser.all.count', 1 do
      IntegrationUser.new_from_slack_oauth(
        user_1,
        omniauth_auth).save!
    end
    iu = IntegrationUser.new_from_slack_oauth(
      user_2,
      omniauth_auth)
    assert iu.invalid?
    assert iu.errors.added?(:oauth_uid, "The combo of data['uid']:U28UKG598 and data['info']['team_id']:T0FR0A8HH already exists")
 end
end
