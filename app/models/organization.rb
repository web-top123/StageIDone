class Organization < ActiveRecord::Base
  include Statistics
  include Profilable
  include IdtIntercom::Organization

  before_validation :update_or_create_slug
  before_validation :set_billing_contact
  before_create :choose_random_profile_color
  before_save :create_hash_id_if_necessary
  before_save :add_autojoin_domain_if_possible

  before_create :create_stripe_customer,            if: :no_stripe_customer_token?
  after_update :update_current_stripe_customer,     if: :billing_info_changed?
  after_update :update_current_stripe_subscription, if: :subscription_changed?

  after_save :add_autojoinable_users_if_possible
  before_validation :set_trial_end_date, on: :create

  mount_uploader :logo, LogoUploader

  validates :autojoin_domain, uniqueness: true, allow_nil: true
  validates :trial_ends_at, presence: true
  validates :plan_level, inclusion: { in: %w(tiny basic small medium large invoice) }, allow_nil: true
  validates :plan_interval, inclusion: { in: %w(monthly yearly) }, allow_nil: true

  has_many :teams, dependent: :destroy

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :active_users, source: :user, through: :active_organization_memberships
  has_many :active_organization_memberships, -> { active }, class_name: 'OrganizationMembership'
  has_many :removed_organization_memberships, -> { removed }, class_name: 'OrganizationMembership'
  has_many :removed_users, source: :user ,through: :removed_organization_memberships

  has_many :invitations, dependent: :destroy
  has_many :entries, through: :teams
  has_many :reactions, through: :entries
  has_many :tags, through: :teams

  scope :alphabetically, -> { order('name asc') }
  scope :on_trial, -> { where('trial_ends_at > ?', Time.current) }
  scope :active, -> { where(stripe_subscription_status: %w[active trialing]) }

  # Flag that this is a migrating acct and skip some filters for migrating
  attr_accessor :is_migrating

  # for admin panel
  def self.filter_fields
    %w(name stripe_customer_token plan_level id hash_id autojoin_domain)
  end

  def to_param
    self.hash_id
  end

  def name_or_something_else_identifying
    return name if name.present?
    'My Organization'
  end

  def outstanding_invitations
    self.invitations.unredeemed
  end

  def owners
    active_users.where(organization_memberships: {role: 'owner'})
  end

  def is_owner?(user)
    owners.where(id: user.id).exists?
  end

  def admins
    active_users.where(organization_memberships: {role: 'admin'})
  end

  def is_admin?(user)
    admins.where(id: user.id).exists?
  end

  def most_active_visible_teams_in_period(start_date, end_date)
    teams.visible
         .select("name, teams.hash_id, count(entries.id) as entry_count, count(comments.id) as comment_count, count(likes.id) as like_count")
         .joins(:entries)
         .where("entries.occurred_on >= ? and entries.occurred_on <= ?", start_date, end_date)
         .joins("LEFT JOIN reactions as comments ON comments.reactable_id = entries.id
                 AND comments.reaction_type = 'comment'
                 AND (comments.created_at >= '#{start_date}' AND comments.created_at <= '#{end_date}')")
         .joins("LEFT JOIN reactions as likes ON likes.reactable_id = entries.id
                 AND likes.reaction_type = 'like'
                 AND (likes.created_at >= '#{start_date}' AND likes.created_at <= '#{end_date}')")
         .group("name, teams.hash_id")
         .order("entry_count desc")
  end

  def on_trial?
    Time.current < trial_ends_at
  end

  def days_left_in_trial
    ((trial_ends_at - Time.zone.now) / 1.day).round
  end

  def trial_elapsed_and_needs_to_upgrade?
    return false if on_trial?
    return false if subscription_active?
    return false if billable_card_on_file? && !subscription_past_due?
    true # no payment method and not on trial -- time to upgrade!
  end

  def stripe_customer
    return nil unless stripe_customer_token
    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_token)
  end

  def plan_name
    AppSetting.human_name_for_plan_level(self.plan_level)
  end

  def plan_stripe_id
    AppSetting.stripe_id_for_plan_level_and_interval(self.plan_level, self.plan_interval)
  end

  def billing_card_type
    return nil unless self.stripe_customer.sources.any?
    self.stripe_customer.sources.first[:brand]
  end

  def billing_card_last_four
    return nil unless self.stripe_customer.present? && self.stripe_customer.sources.any?
    self.stripe_customer.sources.first[:last4]
  end

  def billable_card_on_file?
    return false if is_migrating
    Rails.cache.fetch("#{ self.cache_key }/billable_card") do
      return false unless stripe_customer_token && self.stripe_customer.sources.any?
      self.stripe_customer.sources.first.id.present?
    end
  end

  def subscription_active?
    self.stripe_subscription_status == 'active'
  end

  def subscription_past_due?
    self.stripe_subscription_status == 'past_due'
  end

  def stripe_token=(stripe_token)
    if self.billable_card_on_file?
      # add new credit card
      source  = self.stripe_customer.sources.create(source: stripe_token)
      customer = self.stripe_customer
      customer.default_source = source.id
      customer.save
    else
      # create subscription with new credit card
      subscription = Stripe::Subscription.create(
        customer:    self.stripe_customer_token,
        source:      stripe_token,
        plan:        self.plan_stripe_id,
        quantity:    self.users.count,
        trial_end:   self.on_trial? ? self.trial_ends_at.to_i : 'now'
      )

      self.stripe_subscription_status = subscription.status
    end
  rescue StandardError => e
    errors.add(:base, e.message)
    raise ActiveRecord::Rollback
  end

  def update_subscription_quantity
    return if billed_manually?
    update_current_stripe_subscription
  end

  def estimated_mrr
    return 0 unless (self.stripe_subscription_status == 'active')
    return 0 unless self.plan_level.present? && self.plan_interval.present?
    return 0 unless AppSetting.price_in_cents_for(self.plan_level.to_sym, self.plan_interval.to_sym).present?

    AppSetting.price_in_cents_for(self.plan_level.to_sym,
                                  self.plan_interval.to_sym) * self.active_users.count
  end

  private

  def add_autojoin_domain_if_possible
    return(true) if self.autojoin_domain.present?

    self.owners.each do |owner|
      next if !owner.verified?
      next if owner.free_email_address?
      domain = Mail::Address.new(owner.email_address).domain
      next if domain.blank?
      next if Organization.where(autojoin_domain: domain).any?

      self.autojoin_domain = domain
      return true
    end

    return true
  end

  def add_autojoinable_users_if_possible
    return unless self.autojoin_domain.present?

    User.where(autojoin_domain: self.autojoin_domain).each do |user|
      next if self.users.include? user
      OrganizationMembership.create! organization: self, user: user, role: 'member'
    end

    true
  end

  def create_hash_id_if_necessary
    if self.respond_to?('hash_id') && (self.new_record? || self.hash_id.blank?)
      self.hash_id = Digest::SHA1.hexdigest([Time.now, rand].join)[0,8]
    end
  end

  def update_or_create_slug
    return unless name.present?
    if self.new_record? || self.name_changed? || self.slug.blank?
      self.slug = "#{name.gsub('&','and')}".parameterize
    end
  end

  def set_billing_contact # adds billing info to record if there is a blank
    return true unless self.owners.any?

    if billing_name.blank?
      self.billing_name = self.owners.first.full_name
    end

    if billing_email_address.blank?
      self.billing_email_address = self.owners.first.email_address
    end

    true
  end

  def create_stripe_customer # TODO: asyncify this
    customer = Stripe::Customer.create(
      email: self.billing_email_address,
      description: self.billing_name,
    )
    self.stripe_customer_token = customer.id
  rescue Stripe::InvalidRequestError => e
    Raven.capture_exception(e)
  end

  def update_current_stripe_customer # only if these have changed
    stripe_customer.email = self.billing_email_address
    stripe_customer.description = self.billing_name
    stripe_customer.metadata[:full_name] = self.billing_name
    stripe_customer.save
  rescue Stripe::InvalidRequestError => e
    Raven.capture_exception(e)
  end

  def update_current_stripe_subscription
    if self.stripe_customer && self.stripe_customer.subscriptions.any?
      subscription           = self.stripe_customer.subscriptions.first
      subscription.plan      = self.plan_stripe_id unless self.plan_stripe_id.nil? # legacy plans
      subscription.quantity  = self.active_users.count
      subscription.trial_end = self.on_trial? ? self.trial_ends_at.to_i : 'now'
      subscription.save
    end
  rescue Stripe::InvalidRequestError => e
    Raven.capture_exception(e)
  end

  def set_trial_end_date
    self.trial_ends_at = 14.days.from_now
  end

  def no_stripe_customer_token?
    self.stripe_customer_token.blank?
  end

  def billing_info_changed?
    return self.stripe_customer_token.present? && (self.billing_name_changed? || self.billing_email_address_changed?)
  end

  def subscription_changed?
    return self.stripe_customer_token.present? && (self.plan_level_changed? || self.plan_interval_changed?)
  end
end
