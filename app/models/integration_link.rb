class IntegrationLink < ActiveRecord::Base
  belongs_to :integration_user
  # TODO: Integration links need to be destroyed when a member is taken off a team
  belongs_to :team

  # Existing Integration Types
  # slack-incoming  -  receives entries created via the /done command
  # slack-poster    -  posts a message into slack for every entry created
  # slack-digests   -  posts daily digests into slack
  # github          -  creates entries from Github commits and PRs

  after_initialize :create_token
  validates :integration_user, :team, :token, presence: true
  validate :slack_channel_required, if: Proc.new {|integration_link| integration_link.integration_type == 'slack-poster'}

  def self.for_user(user)
    joins(:integration_user).where(
      integration_users: {user_id: user.id},
      integration_type: ['slack-incoming', 'github']
    )
  end

  def self.for_team(team)
    where(team: team, integration_type: 'slack-poster').all
  end

  def self.slack_slash_command
    case(ENV['DOMAIN_NAME'])
    when /staging/
      '/maybe_done'
    when /idonethis.com/
      '/done'
    else 
      '/local_done'
    end
  end

  def create_token
    self.token = SecureRandom.hex if token.nil?
  end

  def meta_data
    return nil if self['meta_data'].nil?
    JSON.parse(self['meta_data'])
  end

  def summary
    if integration_type == 'slack-incoming'
      "<code>#{IntegrationLink.slack_slash_command}</code> command to <strong>#{team.name}</strong>"
    elsif integration_type == 'slack-poster'
      "<strong>#{team.name}</strong> entries to <strong>#{meta_data['slack_channel']}</strong>"
    elsif integration_type == 'github'
      commits = meta_data.fetch('github',{}).fetch('commits', nil)
      prs = meta_data.fetch('github',{}).fetch('prs', nil)
      org = meta_data.fetch('github',{}).fetch('org', nil)
      repo = meta_data.fetch('github',{}).fetch('repo', nil)
      repo_name = "#{org}/#{repo}"
      type = [ ('Commits' if commits),
               ('PRs' if prs) ].compact.join(' & ')

      "#{type} from <strong>#{repo_name}</strong> to <strong>#{team.name}</strong>"
    end
  end

  def short_name
    if integration_type == 'slack-incoming'
      "Slack"
    elsif integration_type == 'slack-poster'
      "Slack"
    elsif integration_type == 'github'
      "Github"
    end
  end

  def delete_path
    if integration_type == 'slack-incoming' || integration_type == 'slack-poster'
      Rails.application.routes.url_helpers.integrations_slack_link_path
    elsif integration_type == 'github'
      Rails.application.routes.url_helpers.integrations_github_link_path
    end
  end

  private
  def slack_channel_required
    errors.add(:base, 'A slack channel is required') if meta_data.nil? || meta_data.fetch('slack_channel', nil).blank?
  end

end
