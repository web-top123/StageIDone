class Github
  class << self
    def repo_data(integration_user)
      repo_data = {}
      client = Octokit::Client.new(access_token: integration_user.oauth_access_token)
      repos = client.repositories
      orgs = repos.map{|r| r.owner.login}.uniq
      orgs.each do |org|
        repo_data[org] = repos.select{|r| r.owner.login == org}.map{|r| r.name}
      end
      repo_data
    rescue Octokit::Unauthorized
      # TODO: Destroy the integration_user and all links and somehow notify the user.
      # If we get here, it means that they've removed the integration from the Github UI
      # and the account is no longer linked.
    end

    def set_up_webhook(integration_user, token, org, repo)
      Rails.logger.info "========github============set_up_webhook===================================="
      client = Octokit::Client.new(access_token: integration_user.oauth_access_token)
      hook = client.create_hook(
        "#{org}/#{repo}",
        'web',
        {
          url: "https://beta.idonethis.com/integrations/github/hook/#{token}",
          content_type: 'json'
        },
        {
          events: ['push', 'pull_request'],
          active: true
        }
      )
      Rails.logger.info "========github====hook====#{hook.inspect}==================#{hook.id}=================="
      hook.id
    end

    def remove_webhook(integration_user, integration_link)
      client = Octokit::Client.new(access_token: integration_user.oauth_access_token)
      meta_data = integration_link.meta_data
      full_name = "#{meta_data['github']['org']}/#{meta_data['github']['repo']}"
      hook_id   = meta_data['github']['hook_id']
      client.remove_hook(full_name, hook_id)
    rescue StandardError => e
      Raven.capture(e)
    end
  end
end
