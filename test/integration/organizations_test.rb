require 'test_helper'

feature 'Can manage organizations' do
  let(:user)         { users(:user_one) }
  let(:organization) { organizations(:org_one) }

  before do
    # Some sample data taken from Stripe
    customer_data = '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }'
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}')
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/customers', body: customer_data)
    FakeWeb.register_uri(:post,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: customer_data)
    FakeWeb.register_uri(:get,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: customer_data)
    Timecop.freeze(Time.utc(2016,4,1,16,45,8))
    visit login_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: default_password
    click_on 'Login'
  end

  after do
    visit settings_user_path
    click_on 'Logout'
    Timecop.return
  end

  scenario 'it is possible to view teams in organization' do
    visit root_path
    within 'section.account' do
      find('a[href="/o/myorg"]', text: 'My Org').click
    end
    page.must_have_content 'Teams'
    page.must_have_content 'My Team'
    page.must_have_content 'Settings'
  end

  scenario 'it is possible to create new team in organization' do
    visit root_path
    within 'section.account' do
      find('a[href="/o/myorg"]', text: 'My Org').click
    end
    click_on 'Create new team'
    fill_in 'team[name]', with: 'Avengers'
    click_on 'Create team'
    page.must_have_content 'Avengers'
    within 'section.account' do
      find('a[href="/o/myorg"]', text: 'My Org').click
    end
    page.must_have_content 'Avengers'
  end

  scenario 'it is possible to access org settings as admin' do
    visit root_path
    within 'section.account' do
      find('a[href="/o/myorg"]', text: 'My Org').click
    end
    find('a[href="/o/myorg/settings"]', text: 'Settings').click
    within 'form#organization-name-form' do
      fill_in 'organization[name]', with: 'Hydra'
      click_on 'Save Changes'
    end
    assert_equal 'Hydra', organization.name
  end
end
