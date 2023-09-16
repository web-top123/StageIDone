class User < ActiveRecord::Base
  acts_as_paranoid
  include Profilable
  include IdtIntercom::User

  authenticates_with_sorcery! do |config|
    config.authentications_class = Authentication
  end

  has_many :authentications, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :archived_notifications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  after_create :redeem_invitation
  after_create :disable_personal_team_if_necessary
  # after_create :schedule_after_create_jobs
  after_create :verify_email_address_if_necessary
  after_save :create_personal_team_if_necessary
  after_save :create_first_team_if_necessary
  after_save :autojoin_autojoinable_organizations
  after_save :unsubscribe_from_personal_teams
  before_create :choose_random_profile_color
  before_validation :create_api_token
  before_validation :set_sorting_name
  before_validation :set_autojoin_domain
  before_validation :downcase_email, unless: -> { email_address.blank? }
  before_validation :create_go_by_name
  before_validation :set_default_time_zone, if: Proc.new { |user| user.time_zone.blank? }
  before_save :create_hash_id_if_necessary

  validates_plausible_phone :phone_number

  mount_uploader :portrait, PortraitUploader

  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:crypted_password] }
  validates :first_team_name, presence: true, allow_nil: true, if: -> { changes[:first_team_name] }
  validates :email_address, presence: true, uniqueness: true, format: { with: /\A.+@.+\z/ }
  validates :full_name, presence: true, if: -> { changes[:full_name] }

  attr_accessor :invitation_code, :first_team_name

  has_many :entries
  has_many :reactions
  has_many :mentions
  has_many :hooks

  has_many :organization_memberships, dependent: :destroy
  has_many :owned_organization_memberships, -> { owned }, class_name: 'OrganizationMembership'
  has_many :organizations, through: :organization_memberships
  has_many :owned_organizations, source: :organization, through: :owned_organization_memberships
  has_many :active_organization_memberships, -> { active }, class_name: 'OrganizationMembership'
  has_many :active_organizations, -> { order('organizations.name asc') }, source: :organization, through: :active_organization_memberships

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :subscribed_team_memberships, -> { subscribed }, class_name: 'TeamMembership'
  has_many :subscribed_teams, source: :team, through: :subscribed_team_memberships
  has_many :active_team_memberships, -> { active }, class_name: 'TeamMembership'
  has_many :active_teams, -> { order('teams.name asc') }, source: :team, through: :active_team_memberships
  has_many :invitations_sent, class_name: 'Invitation', foreign_key: 'sender_id'

  has_many :alternate_emails, dependent: :destroy
  has_many :integration_users, dependent: :destroy
  has_many :intercom_queues, dependent: :destroy

  scope :verified, -> { where.not(verified_at: nil) }

  scope :has_three_entries, -> { where('entries_count >= 3') }
  # recent -> retained
  scope :has_recent_entries, -> { where('entries_count >= 2').
    joins(:entries).merge(Entry.
                          select('users.id').
                          having('EXTRACT(EPOCH FROM (MAX(entries.created_at) - MIN(entries.created_at))) < ?', 1.week).
                          group('users.id')).select { true } # Was making hashes w/o this
  }
  scope :has_owned_organization, -> { joins(:organization_memberships).
    merge( OrganizationMembership.owned )
  }

  scope :alphabetically, -> { order('sorting_name asc') }

  # for admin panel
  def self.filter_fields
    %w(email_address full_name organization_id id hash_id)
  end

  def self.find_by_email(email)
    return User.find_by(email_address: email)
  end

  def first_name
    return go_by_name if go_by_name.present?
    return namae.given
  end

  def last_name
    namae.family
  end

  def personal_teams
    self.active_teams.where(organization_id: nil)
  end

  def personal_team
    self.personal_teams.first
  end

  def needs_post_migration_onboarding?
    portrait.blank? or go_by_name.blank? or full_name.blank? or !onboarded?
  end

  def first_name_or_something_else_identifying
    return self.first_name if self.first_name.present?
    return something_else_identifying
  end

  def full_name_or_something_else_identifying
    return self.full_name if self.full_name.present?
    return something_else_identifying
  end

  def first_name_and_last_initial
    if namae.family.present?
      "#{namae.given} #{namae.family[0]}."
    else
      namae.given
    end
  end

  def likes?(entry)
    reactions.is_like.where(reactable: entry).any?
  end

  def full_name_initials
    namae.initials.gsub /(\.|-)/, ''
  end

  def is_member_of_organization?(organization)
    organizations.include?(organization)
  end

  def membership_of(team)
    team_memberships.find_by(team_id: team.id)
  end

  def onboarded?
    self.onboarded_at.present?
  end

  def verified?
    self.verified_at.present?
  end

  def migrated?
    self.migrated_from_legacy_at.present?
  end

  def entries_for_team_on_day(team,day)
    self.entries.for_day(day).for_team(team)
  end

  def valid_password?(password)
    if salt.blank? && crypted_password.present?
      LegacyPassword.valid_password?(crypted_password, password)
    else
      super
    end
  end

  def to_param
    self.hash_id
  end

  def organizations_that_need_billing_reminder
    owned_organizations.
    where(billed_manually: false).
    on_trial.
    reject(&:billable_card_on_file?)
  end

  def generate_verification_token!
    self.verification_token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
    self.verification_token_expires_at = Time.zone.now + 3.days
    self.save!
  end

  def verify!
    self.verified_at = Time.zone.now
    self.verification_token = nil
    self.verification_token_expires_at = nil
    self.save!
  end

  def needs_verification?
    # don't care about free emails
    !self.verified? && !free_email_address?
  end

  def free_email_address?
    Freemail.free_or_disposable?(self.email_address)
  end

  def email_address_domain
    Mail::Address.new(self.email_address).domain
  end

  def has_a_potentially_autojoinable_organization?
    org = Organization.find_by(autojoin_domain: self.email_address_domain)
    return false if org.nil? # no need to verify an email that's not associated with an org
    return false if org.users.include?(self) # no need to verify if already a member
    true
  end

  def first_team_name=(value)
    attribute_will_change!('first_team_name') if first_team_name != value # so that changes[:first_team_name] will work in validation conditional
    @first_team_name = value
  end

  def notifications_count
    pending_invitations.count + notifications.count
  end

  def pending_invitations
    Invitation.unredeemed.undeclined.where(email_address: self.email_address)
  end

  def reset_api_token!
      self.update_attribute(:api_token, Digest::SHA1.hexdigest([Time.now, rand].join))
  end

  def clear_notifications!
    self.notifications.each do |notification|
      notification.archive!
    end
  end

  private

  def autojoin_autojoinable_organizations
    return if autojoin_domain.blank?

    org = Organization.find_by(autojoin_domain: self.autojoin_domain)

    return if org.nil?
    return if org.users.include?(self)

    OrganizationMembership.create! organization: org, user: self, role: 'member'

    true
  end

  def namae
    @namae ||= Namae::Name.parse(full_name)
  end

  def something_else_identifying
    return self.nickname if self.nickname.present?
    return self.email_address if self.email_address.present?
    return "User #{ self.hash_id }"
  end

  def create_hash_id_if_necessary
    if self.new_record? || self.hash_id.blank?
      self.hash_id = Digest::SHA1.hexdigest([Time.now, rand].join)[0,8]
    end
  end

  def disable_personal_team_if_necessary
    return unless self.organizations.any?
    self.update_column(:show_personal_team, false)
  end

  def unsubscribe_from_personal_teams
    if !self.show_personal_team
      self.personal_teams.each do |team|
        tm = self.membership_of(team)
        tm.unsubscribe_from_all!
      end
    end
  end

  def create_go_by_name
    if self.go_by_name.blank? && self.full_name.present?
      namae = Namae::Name.parse(self.full_name)
      self.go_by_name = namae.given
    end
  end

  def create_api_token
    if self.api_token.blank?
      self.api_token = Digest::SHA1.hexdigest([Time.now, rand].join)
    end
  end

  def verify_email_address_if_necessary
    return if free_email_address? # no need to verify a free email address
    return unless has_a_potentially_autojoinable_organization?

    # an org this person can autojoin exists ... send 'em an email

    VerificationEmailWorker.perform_async(self.id)
  end

  def redeem_invitation
    return unless self.invitation_code.present?
    invitation = Invitation.where(invitation_code: self.invitation_code).first
    return unless invitation && !invitation.is_redeemed?

    OrganizationMembership.create!(role: 'member', organization: invitation.organization, user: self)
    invitation.teams.each { |t| TeamMembership.create!(team: t, user: self) }

    invitation.redeem_invitation!
  end

  def set_autojoin_domain
    return true if self.autojoin_domain.present?
    self.autojoin_domain = if !self.verified? or self.free_email_address?
      '' # the user is not verified or has a free email address so this is blank
    else
      self.email_address_domain
    end
  end

  def set_sorting_name
    self.sorting_name = namae.sort_order
  end

  def downcase_email
    self.email_address.downcase!
  end

  def schedule_after_create_jobs
    if !migrated? # don't do this for migrated users
      SalesforceLeadWorker.perform_in(1.minute, self.id)
    end
  end

  def create_first_team_if_necessary
    return(true) unless self.first_team_name.present?
    return(true) if self.organizations.any?

    org = Organization.create!(billing_name: self.full_name, billing_email_address: self.email_address)
    om = OrganizationMembership.create!(organization: org, user: self, role: 'owner')
    team = Team.create!(name: self.first_team_name, organization: org ,owner_id: self.id)
    tm = TeamMembership.create!(team: team, user: self)
  end

  def create_personal_team_if_necessary
    return true if self.personal_teams.any?
    return true unless self.show_personal_team
    t = Team.create! name: "Personal progress log"
    tm = TeamMembership.create! team: t, user: self

    true
  end

  def set_default_time_zone
    self.time_zone = 'Pacific Time (US & Canada)'
  end
end
