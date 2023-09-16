module TestSubscriptionHelper
  include ActionView::Helpers::NumberHelper

  def subscribe_to(user, organization, plan, interval, subscribe_at=nil)
    travel_to subscribe_at unless subscribe_at.nil?

    # plan page
    visit organization_upgrade_path(organization)
    choose interval_option(interval, plan)
    click_on "Choose #{plan}"

    # credit card page
    set_mock_stripe_token StripeMock.generate_card_token()
    fill_in 'Name on card', with: user.full_name
    click_on 'Continue'

    # clears the cached ivar which is what would happen between requests
    organization.instance_variable_set(:@stripe_customer, nil)
  end

  def interval_option(interval, plan)
    internal_plan = case plan
    when 'Standard'
      :small
    when 'Plus'
      :medium
    when 'Enterprise'
      :large
    else
      raise "Invalid plan #{plan}"
    end

    if interval == 'annually'
      "Annually #{ format_cents AppSetting.plan_price_in_cents_per_user(internal_plan, :yearly) } per user"
    elsif interval == 'monthly'
      "Monthly #{ format_cents AppSetting.plan_price_in_cents_per_user(internal_plan, :monthly) } per user"
    else
      raise "Invalid plan interval #{interval}"
    end        
  end

  def format_cents(cents)
    number_to_currency(cents / 100.0).gsub(/\.00$/, "")
  end

  def set_mock_stripe_token(token)
    page.execute_script("$('#mock-stripe-token').data('stripe-token', '#{token}')")
  end

  def log_subscription(subscription)
    puts "Today is #{Date.current}"

    p subscription
    puts "status = #{subscription.status}"
    puts "current_period_start = #{Time.zone.at(subscription.current_period_start)}"
    puts "current_period_end = #{Time.zone.at(subscription.current_period_end)}"

    puts "trial_start = #{Time.zone.at(subscription.trial_start)}" if subscription.trial_start.present?
    puts "trial_end = #{Time.zone.at(subscription.trial_end)}" if subscription.trial_end.present?
    puts "trials days = #{(Time.zone.at(subscription.trial_end).to_date - Time.zone.at(subscription.trial_start).to_date)}" if subscription.trial_end.present?
  end

end
