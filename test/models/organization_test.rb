require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  let(:stripe_customer) { '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }' }

  before do
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}')
  end

  test 'creating a new organization' do
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/customers', body: stripe_customer)
    organization = Organization.create
    assert organization.valid?
  end

  test 'creating new organization without a stripe customer token invokes create_stripe_customer' do
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/customers', body: stripe_customer)
    organization = Organization.new
    organization.expects(:create_stripe_customer).returns(true)
    organization.save
  end

  test 'saving an existing organization without a stripe customer token does not invoke create_stripe_customer' do
    organization = organizations(:org_one)
    organization.stripe_customer_token = nil
    organization.expects(:create_stripe_customer).never
    organization.save
  end

  test 'creating new organization with a stripe customer token does not invoke create_stripe_customer' do
    organization = Organization.new(stripe_customer_token: "ABC")
    organization.expects(:create_stripe_customer).never
    organization.save
  end

  test 'create a new organization does not invoke update_current_stripe_subscription' do
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/customers', body: stripe_customer)
    organization = Organization.new
    organization.expects(:update_current_stripe_subscription).never
    organization.save
  end

  test 'saving an existing paid organization does not invoke update_current_stripe_subscription' do
    organization = organizations(:paid_organization)
    organization.expects(:update_current_stripe_subscription).never
    organization.save
  end

  test 'updating the plan level for an paid existing organization does invoke update_current_stripe_subscription' do
    organization = organizations(:paid_organization)
    organization.plan_level = 'medium'
    organization.expects(:update_current_stripe_subscription).returns(true)
    organization.save
  end

end
