class SlackEntryPosterWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 6

  def perform(entry_id, integration_link_id)
    entry = Entry.eager_load(:user).find(entry_id)
    integration_link = IntegrationLink.find(integration_link_id)
    integration_user = integration_link.integration_user
    client = Slack::Web::Client.new(token: integration_user.oauth_access_token)
    client.chat_postMessage(
      channel: integration_link.meta_data['slack_channel'],
      username: 'i done this',
      icon_url: 'https://beta.idonethis.com/apple-touch-icon-180x180.png',
      attachments: [{
        "fallback": entry.body,
        "text": entry.body,
        "fields": [
          { "title": "User", "value": entry.user.first_name_or_something_else_identifying, "short": true },
          { "title": entry.status.capitalize, "value": entry.occurred_on.to_s, "short": true }
        ],
        "color": attachment_color(entry.status)
      }]
    )
  rescue Slack::Web::Api::Error => e
    if e.message == 'token_revoked' || e.message == 'is_archived' || e.message == 'channel_not_found'
      # This integration link is with an invalid channel or has been revoked from slack
      IntegrationLink.find(integration_link_id).destroy
    else
      Raven.capture_message "Slack Api Error in SlackEntryPosterWorker when trying to post entry for integration link ID##{integration_link_id}: #{e}", 
        extra: {entry_id: entry_id, integration_link_id: integration_link_id}
    end
  end

  def attachment_color(status)
    case status
    when 'done'
      '#7CD197'
    when 'goal'
      '#478CFE'
    when 'blocked'
      '#E94B35'
    end
  end
end
