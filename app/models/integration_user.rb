# TODO: Explain this, multiple types of integration users, by oauth or api key
# oauth is required now but api key is a sensible extension in the future and then validations
# would need to be conditional
class IntegrationUser < ActiveRecord::Base
  include IdtIntercom::IntegrationUser

  belongs_to :user
  has_many :integration_links, dependent: :destroy

  validates :user, :oauth_uid, :oauth_access_token, presence: true
  validate :unique_slack_user, if: "integration_type == 'slack'"

  def unique_slack_user
    if self.class.find_slack_integration_user_by_oauth_id_and_team_id(oauth_uid, meta_data['slack_team_id']).present?
      errors.add(:oauth_uid, "The combo of data['uid']:#{oauth_uid} and data['info']['team_id']:#{meta_data['slack_team_id']} already exists")
    end
  end

  def self.new_from_github_oauth(user, data)
    new(
      user: user,
      integration_type: 'github',
      oauth_uid: data['uid'],
      oauth_access_token: data['credentials']['token'],
      oauth_access_token_expires: data['credentials']['expires'],
      meta_data: {
        nickname: data['info']['nickname'],
        email: data['info']['email']
      }.to_json
    )
  end

  def self.new_from_slack_oauth(user, data)
    new(
      user: user,
      integration_type: 'slack',
      oauth_uid: data['uid'],
      oauth_access_token: data['credentials']['token'],
      oauth_access_token_expires: data['credentials']['expires'],
      meta_data: {
        slack_user_name: data['info']['user'],
        slack_team_name: data['info']['team'],
        slack_team_id: data['info']['team_id']
      }.to_json
    )
  end

  def meta_data
    return nil if self['meta_data'].nil?
    JSON.parse(self['meta_data'])
  end

  def self.find_slack_integration_user_by_oauth_id_and_team_id(slack_user_id, slack_team_id)
    IntegrationUser.where(oauth_uid: slack_user_id).find { |iu_elem| iu_elem.meta_data['slack_team_id'] == slack_team_id }
  end
end
