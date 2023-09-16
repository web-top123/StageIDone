require 'test_helper'

describe OrganizationMembershipsController do
  before do
    customer_data = '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }'
    FakeWeb.register_uri(:get,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: customer_data)
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}')
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/subscriptions/sub_8lopgdmOmdAiqd', body: '{}')
    login_user(users(:user_one))
  end

  test 'can change role of someone' do
    o = organizations(:org_one)
    om = OrganizationMembership.create(organization: o, user: users(:user_two), role: 'member')
    put :update, organization_id: o.hash_id, id: om.id, organization_membership: {role: 'owner'}
    om.reload
    assert_equal 'owner', om.role
  end
end
