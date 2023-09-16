class OrganizationMembership < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :organization
  belongs_to :user

  after_save :update_subscription_quantity
  after_destroy :update_subscription_quantity

  validates :user_id, presence: true, uniqueness: {scope: :organization_id}
  validates :organization_id, presence: true, uniqueness: {scope: :user_id}
  validates :role, inclusion: { in: %w(owner admin member) }

  scope :owned, -> { active.where(role: 'owner') }
  scope :alphabetically, -> { includes(:user).order('users.sorting_name asc') }
  scope :active, -> { where(removed_at: nil) }
  scope :removed, -> { where.not(removed_at: nil) }

  # This is _just_ for migration purposes, remove when migrations are no longer done
  attr_accessor :skip_quantity_update

  def self.role_options
    %w(owner admin member)
  end

  def remove!
    self.transaction do
      self.removed_at = Time.zone.now
      self.save!
      remove_user_from_organization_teams!
    end
  end

  def join!
    self.removed_at = nil
    self.save!
  end

  private

  def update_subscription_quantity
    return if skip_quantity_update || self.organization.nil?
    self.organization.update_subscription_quantity
  end

  def remove_user_from_organization_teams!
    self.user.team_memberships.active.where(team_id: self.organization.teams.pluck(:id)).each(&:remove!)
  end
end
