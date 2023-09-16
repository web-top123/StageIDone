class Team < ActiveRecord::Base
  include Statistics

  has_many :team_memberships, dependent: :delete_all #team_memberships are using acts_as_paranoid but from team we want the records deleted
  has_many :users, through: :team_memberships
  has_many :active_team_memberships, -> { active }, class_name: 'TeamMembership'
  has_many :active_users, source: :user, through: :active_team_memberships
  has_many :removed_team_memberships, -> { removed }, class_name: 'TeamMembership'
  has_many :removed_users, source: :user, through: :removed_team_memberships
  has_many :entries, dependent: :destroy
  has_many :reactions, through: :entries
  has_many :hooks, dependent: :destroy
  has_many :tags, -> { distinct },through: :entries
  has_many :integration_links, dependent: :destroy

  belongs_to :organization

  scope :alphabetically, -> { order('name asc') }
  scope :visible, -> { where(public: true) }
  scope :non_personal, -> { where.not(organization_id: nil) }

  validates :name, presence: true, uniqueness: {scope: :organization_id}, if: "organization_id.present?"

  before_save :create_hash_id_if_necessary
  before_validation :update_or_create_slug
  after_destroy :remove_any_team_invitations

  # for admin panel
  def self.filter_fields
    %w(name organization_id id hash_id)
  end

  def members_at(date)
    users.with_deleted
         .where("team_memberships.created_at <= ?", date.end_of_day)
         .where("team_memberships.removed_at >= ? or team_memberships.removed_at IS NULL", date.beginning_of_day)
         .where("team_memberships.deleted_at >= ? or team_memberships.deleted_at IS NULL", date.beginning_of_day)
  end

  def to_param
    self.hash_id
  end

  def outstanding_invitations
    self.organization.invitations.unredeemed.for_team(self)
  end

  def prompt_for(status_type)
    self.send "prompt_#{ status_type.downcase }"
  end

  def private?
    !self.public
  end

  def personal?
    !self.organization_id.present?
  end

  private

  def create_hash_id_if_necessary
    if self.respond_to?('hash_id') && (self.new_record? || self.hash_id.blank?)
      self.hash_id = Digest::SHA1.hexdigest([Time.now, rand].join)[0,12]
    end
  end

  def update_or_create_slug
    if self.new_record? || self.slug.blank?
      self.slug = "#{name.gsub('&','and')}".parameterize
    end
  end

  def remove_any_team_invitations
    Invitation.for_team(self).each do |invitation|
      if invitation.team_ids.size > 1 # invitation for multiple teams
        invitation.team_ids.delete(self.id)
        invitation.save
      else
        invitation.destroy
      end
    end
  end
end
