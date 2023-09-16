require 'test_helper'

describe Integrations::SlackController do
  let (:user_one) { users(:user_one) }
  let (:april_01_2016_midnight) { Time.utc(2016,4,1,0,0,0) }

  before do
    sample_channels = '{ "ok": true, "channels": [ { "id": "C024BE91L", "name": "fun", "created": 1360782804, "creator": "U024BE7LH", "is_archived": false, "is_member": false, "num_members": 6, "topic": { "value": "Fun times", "creator": "U024BE7LV", "last_set": 1369677212 }, "purpose": { "value": "This channel is for fun", "creator": "U024BE7LH", "last_set": 1360782804 } } ] }'
    FakeWeb.register_uri(:post, 'https://slack.com/api/channels.list', body: sample_channels, :content_type => "application/json")
    FakeWeb.register_uri(:post, 'https://slack.com/api/chat.postMessage', body: '{ "ok": true }', :content_type => "application/json")
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:slack] = OmniAuth::AuthHash.new({
        'provider' => 'slack',
        'uid' => '1234512345',
        'credentials' => {'token' => 'abcd', 'expires' => false},
        'info' => {
          'user' => 'folsen',
          'team' => 'idonethis',
          'team_id' => 'T123'
        }
    })

    login_user(user_one)
  end

  describe 'User interactions' do
    test 'can create integration user' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]

      assert_difference 'IntegrationUser.count', 1 do
        get :oauth_callback
      end
      assert_redirected_to integrations_slack_link_path
    end

    test 'can view new integration link form' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      get :new_link
      assert_response :success
      assert_match 'Add Slack integration', response.body
      assert_match 'fun', response.body
    end

    test 'can create slack-poster integration link' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      assert_difference 'IntegrationLink.count', 1 do
        post :create_link,
              integration_link: {
                team_id: teams(:team_one).id,
                integration_user_id: IntegrationUser.last.id,
                integration_type: 'slack-poster'
              },
              slack_channel: 'idt'
      end
      assert_redirected_to settings_team_path(teams(:team_one))
    end

    test 'can create slack-incoming integration link' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      assert_difference 'IntegrationLink.count', 1 do
        post :create_link,
          integration_link: {
            team_id: teams(:team_one).id,
            integration_user_id: IntegrationUser.last.id,
            integration_type: 'slack-incoming'
          }
      end
      assert_redirected_to settings_user_path
    end

    test 'can destroy integration link' do
      request.env["HTTP_REFERER"] = '/'
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      post :create_link,
        integration_link: {team_id: teams(:team_one).id, integration_user_id: IntegrationUser.last.id}

      delete :destroy_link, integration_link_id: IntegrationLink.last.id
      assert_redirected_to root_path
    end

    test 'should get a friendly message if integration not hooked up' do
      post :hook, {
        token: ENV['SLACK_APP_VERIFICATION_TOKEN'],
        user_id: '1234512345',
        text: 'new entry'
      }
      assert_response :success
      assert_match 'app.idonethis.com/integration', response.body
    end

    test 'slack-poster integration calls worker' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      post :create_link,
        integration_link: {
          team_id: teams(:team_one).id,
          integration_user_id: IntegrationUser.last.id,
          integration_type: 'slack-poster'
        },
        slack_channel: 'fun'

      # This will call the worker, so the worker is tested as well implicitly
      Entry.create(user: user_one, team: teams(:team_one), body: 'testing worker', status: 'done', occurred_on: Date.current)
      Entry.create(user: user_one, team: teams(:team_one), body: 'testing worker', status: 'goal', occurred_on: Date.current)
      Entry.create(user: user_one, team: teams(:team_one), body: 'testing worker', status: 'blocked', occurred_on: Date.current)
    end
  end

  describe 'Webhook callbacks' do
    before do
      travel_to april_01_2016_midnight
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
      get :oauth_callback

      post :create_link,
        integration_link: {
          team_id: teams(:team_one).id,
          integration_user_id: IntegrationUser.last.id,
          integration_type: 'slack-incoming'
        }
    end

    after do
      travel_back
    end

    test 'valid hook request' do
      user_one.time_zone = "Pacific Time (US & Canada)"
      user_one.save!
      
      assert_difference 'Entry.count', 1 do
        post :hook, {
          token: ENV['SLACK_APP_VERIFICATION_TOKEN'],
          user_id: '1234512345',
          text: 'new entry'
        }
        assert_response :success
      end
      assert_equal 'new entry', Entry.last.body
      # Since Pacific Time is -0700, and occurred_on is date based on
      # the time zone user is in, so the date is day before current date
      assert_equal 1.day.ago.to_date, Entry.last.occurred_on
      assert_equal 'done', Entry.last.status
    end

    test 'invalid hook request' do
      post :hook, {
        token: 'somethingelse',
        user_id: '1234512345',
        text: 'new entry'
      }
      assert_response 401
    end

  end
end
