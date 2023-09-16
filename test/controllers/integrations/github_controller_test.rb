require 'test_helper'

describe Integrations::GithubController do
  before do
    sample_repos = '[ { "id": 53505743, "name": "amqp-processor", "full_name": "folsen/amqp-processor", "owner": { "login": "folsen", "id": 8249, "avatar_url": "https://avatars.githubusercontent.com/u/8249?v=3", "gravatar_id": "", "type": "User", "site_admin": false } }, { "id": 24731650, "name": "anne-droid", "full_name": "folsen/anne-droid", "owner": { "login": "folsen", "id": 8249, "avatar_url": "https://avatars.githubusercontent.com/u/8249?v=3", "gravatar_id": "", "type": "User", "site_admin": false } }]'
    FakeWeb.register_uri(:get, 'https://api.github.com/user/repos?per_page=100', body: sample_repos, :content_type => "application/json")
    FakeWeb.register_uri(:post, 'https://api.github.com/repos/folsen/amqp-processor/hooks', body: {id: 1}.to_json, :content_type => "application/json")
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
        'provider' => 'github',
        'uid' => '1234512345',
        'credentials' => {'token' => 'abcd', 'expires' => false},
        'info' => {
          'nickname' => 'folsen',
          'email' => 'fredrik@idonethis.com'
        }
    })

    login_user(users(:user_one))
  end

  describe 'User interactions' do
    test 'can create integration user' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]

      assert_difference 'IntegrationUser.count', 1 do
        get :oauth_callback
      end
      assert_redirected_to integrations_github_link_path
    end

    test 'can view new integration link form' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
      get :oauth_callback

      get :new_link
      assert_response :success
      assert_match 'Add Github integration', response.body
      assert_match 'amqp-processor', response.body
    end

    test 'can create integration link' do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
      get :oauth_callback

      assert_difference 'IntegrationLink.count', 1 do
        post :create_link,
          integration_link: {team_id: teams(:team_one).id, integration_user_id: IntegrationUser.last.id},
          github: {org: 'folsen', repo: 'amqp-processor', commits: '1', prs: nil}
      end
      assert_redirected_to settings_user_path
    end

    test 'can destroy integration link' do
      # TODO: Probably a case for FactoryGirl?
      request.env["HTTP_REFERER"] = '/'
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
      get :oauth_callback

      post :create_link,
        integration_link: {team_id: teams(:team_one).id, integration_user_id: IntegrationUser.last.id},
        github: {org: 'folsen', repo: 'amqp-processor', commits: '1', prs: nil}

      delete :destroy_link, integration_link_id: IntegrationLink.last.id
      assert_redirected_to root_path
    end
  end

  describe 'Webhook callbacks' do
    before do
      Timecop.freeze(Time.utc(2016,4,1,16,45,8))
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
      get :oauth_callback

      post :create_link,
        integration_link: {team_id: teams(:team_one).id, integration_user_id: IntegrationUser.last.id},
        github: {org: 'folsen', repo: 'amqp-processor', commits: '1', prs: '1'}
    end

    after do
      Timecop.return
    end

    test 'commit hook' do
      request.headers['X-Github-Event'] = 'push'
      assert_difference 'Entry.count', 1 do
        post :hook, token: IntegrationLink.last.token,
          commits: [{ distinct: true, author: {username: 'folsen'}, message: 'new entry', timestamp: Time.current}]
        assert_response :success
      end
      assert_equal 'new entry', Entry.last.body
      assert_equal Date.new(2016,4,1), Entry.last.occurred_on
      assert_equal 'done', Entry.last.status
    end

    test 'pr hook' do
      request.headers['X-Github-Event'] = 'pull_request'
      assert_difference 'Entry.count', 1 do
        post :hook,
          {ghaction: 'closed', token: IntegrationLink.last.token, pull_request: { merged: true, user: {id: '1234512345'}, title: 'new entry', closed_at: Time.current}}
        assert_response :success
      end
      assert_equal 'new entry', Entry.last.body
      assert_equal Date.new(2016,4,1), Entry.last.occurred_on
      assert_equal 'done', Entry.last.status
    end

    test 'does not break on unknown event type' do
      request.headers['X-Github-Event'] = 'unknown_event'
      assert_difference 'Entry.count', 0 do
        post :hook, token: IntegrationLink.last.token
        assert_response :success
      end
    end
  end
end
