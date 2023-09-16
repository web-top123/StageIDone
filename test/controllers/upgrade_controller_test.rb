require 'test_helper'

describe UpgradeController do

  describe "paid organization" do
    let(:stripe_customer) { '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [{"id":"card_18wKAyJB5ipbWavERyGgiw0G"}], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }' }
    let(:organization)    { organizations(:org_one) }
    let(:user)            { users(:user_one) }

    before do
      login_user(user)
    end

    test 'can view plans' do
      FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}') # create the default plans
      FakeWeb.register_uri(:get,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: stripe_customer)
      get :show, organization_id: organization.hash_id
      assert_response :success
    end

    test 'can change plan' do
      FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}') # create the default plans
      FakeWeb.register_uri(:get,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: stripe_customer)
      FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/subscriptions/sub_8lopgdmOmdAiqd', body: '{}')

      get :billing, organization_id: organization.hash_id, plan: 'medium', interval: 'monthly'
      assert_redirected_to settings_organization_path(organization)
    end
  end

  describe "trial organization" do
    let(:organization) { organizations(:trial_organization) }
    let(:user)         { users(:user_four) }

    before do
      StripeMock.start
      # because the fixture is created already create_stripe_customer is outside of the StripeMock.start
      customer = Stripe::Customer.create(
        email: organization.billing_email_address,
        description: organization.billing_name,
      )
      organization.update_attribute(:stripe_customer_token, customer.id)
      login_user(user)
    end

    after do
      StripeMock.stop
    end

    test 'can complete new subscription' do  
      put :complete, organization_id: organization.hash_id,
        organization: {
          plan_interval: 'monthly',
          plan_level: 'tiny',
          billing_name: 'George Washington',
          stripe_token: StripeMock.generate_card_token()
        }
      assert_redirected_to organization_path(organization)
    end
  end

end
