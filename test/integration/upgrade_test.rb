require 'test_helper'
require 'support/test_subscription_helper'

feature 'Upgrade Plan' do
  include TestSubscriptionHelper

  let(:user)            { users(:user_four) }
  let(:user_two)        { users(:user_two) }
  let(:organization)    { organizations(:trial_organization) }
  let(:stripe_customer) { organization.reload.stripe_customer }
  let(:subscription)    { stripe_customer.subscriptions.first }
  let(:new_credit_card) { {number: "5555555555554444", exp_month: 10, exp_year: 2021, cvc: "123" } }
  let(:default_card)    { stripe_customer.sources.retrieve(stripe_customer.default_source) }

  let(:five_days_since_trial_ended) { organization.trial_ends_at.days_since(5) }

  before do
    StripeMock.start
    # because the fixture is created already create_stripe_customer is outside of the StripeMock.start
    customer = Stripe::Customer.create(
      email: organization.billing_email_address,
      description: organization.billing_name,
    )
    organization.update_attribute(:stripe_customer_token, customer.id)
    visit login_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: default_password
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    travel_back
    StripeMock.stop
  end

  scenario "subscribe the organization to a monthly plus plan whilst still in trial period", js: true do
    subscribe_to user, organization, 'Plus', 'monthly'

    page.must_have_content 'Your organization is all set. Thanks for choosing I Done This.'

    assert_equal 'trialing', subscription.status
    assert_equal 'medium-monthly-v3', subscription.plan.id
    assert_equal 'month', subscription.plan.interval
    assert_equal Date.current, Time.zone.at(subscription.trial_start).to_date
    assert_equal organization.trial_ends_at.to_i, subscription.trial_end
    assert_equal Date.current, Time.zone.at(subscription.current_period_start).to_date
    assert_equal organization.trial_ends_at.to_i, subscription.current_period_end
    assert_equal 2, subscription.quantity

    assert_equal 'trialing', organization.stripe_subscription_status
    assert_equal 'medium-monthly-v3', organization.plan_stripe_id
    assert_equal 'monthly', organization.plan_interval
    assert_equal 'medium', organization.plan_level
  end

  scenario "subscribe the organization to a annual standard plan 5 days after the trial period", js: true do
    subscribe_to user, organization, 'Standard', 'annually', five_days_since_trial_ended

    page.must_have_content 'Your organization is all set. Thanks for choosing I Done This.'

    assert_equal 'active', subscription.status
    assert_equal 'small-yearly-v3', subscription.plan.id
    assert_equal 'year', subscription.plan.interval
    assert_nil subscription.trial_start
    assert_nil subscription.trial_end
    assert_equal Date.current, Time.zone.at(subscription.current_period_start).to_date
    assert_equal 1.year.from_now, Time.zone.at(subscription.current_period_end)
    assert_equal 2, subscription.quantity

    assert_equal 'active', organization.stripe_subscription_status
    assert_equal 'small-yearly-v3', organization.plan_stripe_id
    assert_equal 'yearly', organization.plan_interval
    assert_equal 'small', organization.plan_level
  end

  scenario "downgrade the organization from plus plan to standard plan 10 days later", js: true do
    subscribe_to user, organization, 'Plus', 'annually', five_days_since_trial_ended

    travel 10.days

    visit organization_upgrade_path(organization)
    click_on 'Choose Standard'

    assert_equal 'active', subscription.status
    assert_equal 'small-yearly-v3', subscription.plan.id
    assert_equal 'year', subscription.plan.interval
  end

  scenario "subscribe the organization with an invalid credit card", js: true do
    StripeMock.prepare_card_error(:card_declined, :create_subscription)

    subscribe_to user, organization, 'Plus', 'monthly'

    page.must_have_content 'The card was declined'
  end

  scenario 'subscribed organization updates billing info and credit card', js: true do
    subscribe_to user, organization, 'Plus', 'monthly'
    visit settings_organization_path(organization)
    set_mock_stripe_token StripeMock.generate_card_token(new_credit_card)
    find('a', text: 'Update Credit Card').click
    within 'form#billing-details' do
      fill_in 'Name on card', with: 'Was Four'
      click_on 'Save Changes'
    end

    page.must_have_content 'This account is billed to: Was Four'
    assert_equal 'Was Four', stripe_customer.description
    assert_equal 'Was Four', stripe_customer.metadata[:full_name]
    assert_equal 2, stripe_customer.sources.count

    assert_equal '4444', default_card.last4
    assert_equal 10,     default_card.exp_month
    assert_equal 2021,   default_card.exp_year
  end

  scenario 'subscribed organization adds new member', js: true do
    subscribe_to user, organization, 'Plus', 'annually', five_days_since_trial_ended

    assert_equal 2, subscription.quantity

    OrganizationMembership.create!(role: 'member', organization: organization, user: user_two)

    assert_equal 3, subscription.quantity
  end

  scenario 'trial organization adds new member, then subscribes', js: true do
    OrganizationMembership.create!(role: 'member', organization: organization, user: user_two)

    subscribe_to user, organization, 'Plus', 'annually', five_days_since_trial_ended

    assert_equal 3, subscription.quantity
  end

end
