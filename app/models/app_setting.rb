# This is the main class/setting for Plans.
class AppSetting < ActiveRecord::Base
  after_create :create_default_plans_in_stripe
  validates :tiny_monthly_plan_id,
            :tiny_monthly_plan_price_in_cents,
            :tiny_yearly_plan_id,
            :tiny_yearly_plan_price_in_cents,
            :basic_monthly_plan_id,
            :basic_monthly_plan_price_in_cents,
            :basic_yearly_plan_id,
            :basic_yearly_plan_price_in_cents,
            :small_monthly_plan_id,
            :small_monthly_plan_price_in_cents,
            :small_yearly_plan_id,
            :small_yearly_plan_price_in_cents,
            :medium_monthly_plan_id,
            :medium_monthly_plan_price_in_cents,
            :medium_yearly_plan_id,
            :medium_yearly_plan_price_in_cents,
            :large_monthly_plan_id,
            :large_monthly_plan_price_in_cents,
            :large_yearly_plan_id,
            :large_yearly_plan_price_in_cents,
            :invoice_monthly_plan_id,
            :invoice_monthly_plan_price_in_cents,
            :invoice_yearly_plan_id,
            :invoice_yearly_plan_price_in_cents,
            presence: true

  def self.current
    latest = last
    if latest
      latest
    else
      create_default
    end
  end

  def self.human_name_for_plan_level(plan_level_str)
    return 'Legacy' if plan_level_str.nil?
    {
      tiny: 'Hobby',
      basic: 'Basic',
      small: 'Standard',
      medium: 'Plus',
      large: 'Enterprise'
    }[plan_level_str.to_sym]
  end

  def self.human_name_for_plan_interval(plan_interval_str)
    case plan_interval_str.to_sym
    when :monthly
      "Monthly"
    when :yearly
      "Annually"
    else
      "Unknown"
    end
  end

  def self.stripe_id_for_plan_level_and_interval(plan_str,interval_str)
    get "#{ plan_str }_#{ interval_str }_plan_id".to_sym
  end

  def self.price_in_cents_for(plan_str,interval_str)
    get "#{ plan_str }_#{ interval_str }_plan_price_in_cents".to_sym
  end

  def self.plan_price_in_cents_per_user(plan_str,interval_str)
    price = get "#{ plan_str }_#{ interval_str }_plan_price_in_cents".to_sym
    if interval_str.to_sym == :yearly
      price * 12
    else
      price
    end
  end

  def self.create_default
    create(
      tiny_monthly_plan_id:     'tiny-monthly-v3',
      tiny_yearly_plan_id:      'tiny-yearly-v3',
      basic_monthly_plan_id:    'basic-monthly',
      basic_yearly_plan_id:     'basic-yearly',
      small_monthly_plan_id:    'small-monthly-v3',
      small_yearly_plan_id:     'small-yearly-v3',
      medium_monthly_plan_id:   'medium-monthly-v3',
      medium_yearly_plan_id:    'medium-yearly-v3',
      large_monthly_plan_id:    'large-monthly-v3',
      large_yearly_plan_id:     'large-yearly-v3',
      invoice_monthly_plan_id:  'invoice_monthly_v1',
      invoice_yearly_plan_id:   'invoice_yearly_v1'
    )
  end

  def self.get(sym)
    return nil unless current.respond_to?(sym)
    current.send(sym)
  end

  def self.from(value)
    current.attributes.each do |k,v|
      return k if value == v
    end
    nil
  end

  def self.plans
    [ :tiny_monthly_plan_id, :tiny_yearly_plan_id,
      :basic_monthly_plan_id, :basic_yearly_plan_id,
      :small_monthly_plan_id, :small_yearly_plan_id,
      :medium_monthly_plan_id, :medium_yearly_plan_id,
      :large_monthly_plan_id, :large_yearly_plan_id,
      :invoice_monthly_plan_id, :invoice_yearly_plan_id]
  end

  def self.stripe_plan_id_to_internal(plan_id)
    matches = plan_id.match(/([a-zA-Z0-9]+)\-([a-zA-Z0-9]+)\-([v0-9]+)/)
    return nil if matches.nil? || matches[1].nil? || matches[2].nil?
    plan_level = matches[1]
    plan_interval = matches[2]
    return plan_level, plan_interval
  end

  private

  # this should live in `Plan` or something

  def create_default_plans_in_stripe
    self.class.plans.each do |plan|
      plan_id = self.class.get(plan.to_sym)
      plan_name = plan_id.gsub('-',' ').capitalize # lol
      plan_interval = plan.to_s.include?('monthly') ? 'month' : 'year'
      price_in_cents = if plan_interval == 'year'
        self.class.get(plan.to_s.gsub('_id','_price_in_cents').to_sym) * 12
      else
        self.class.get(plan.to_s.gsub('_id','_price_in_cents').to_sym)
      end

      begin
        Stripe::Plan.create(
          amount: price_in_cents,
          id: plan_id,
          name: plan_name,
          interval: plan_interval,
          currency: 'usd',
          # trial_period_days: 14
          trial_period_days: 3
        )
      rescue Stripe::InvalidRequestError => e
        Raven.capture_exception(e)
      end
    end
  end
end
