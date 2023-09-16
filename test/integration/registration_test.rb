require 'test_helper'

feature 'Can register' do
  let(:stripe_customer) { '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }' }
  let(:team) { Team.last }

  before do
    FakeWeb.register_uri(:post, 'https://login.salesforce.com/services/oauth2/token', body: 'ok')
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}')
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/customers', body: stripe_customer)
    FakeWeb.register_uri(:get, 'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: stripe_customer)
    FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/subscriptions/sub_8lopgdmOmdAiqd', body: '{}')
  end

  scenario 'registration page exists' do
    visit register_path
    page.must_have_content 'Sign up'
  end

  scenario 'registering but planning to use a team' do
    visit register_path
    fill_in 'user[full_name]', with: 'John Doe'
    fill_in 'user[email_address]', with: 'john@doe.com'
    fill_in 'user[password]', with: 'password'
    click_on 'Continue'
    page.must_have_content 'Is this your full name?'
    page.must_have_content 'What is your team called?'
    click_on "I don't plan to use I Done This with a team"
    assert_current_path team_path(team)
  end

  scenario 'registering without entering a team name' do
    visit register_path
    fill_in 'user[full_name]', with: 'John Doe'
    fill_in 'user[email_address]', with: 'john@doe.com'
    fill_in 'user[password]', with: 'password'
    click_on 'Continue'
    page.must_have_content 'Is this your full name?'
    page.must_have_content 'What is your team called?'
    click_on 'Continue'
    page.must_have_content "First team name can't be blank"
  end

  scenario 'registering without inviting people to my team' do
    visit register_path
    fill_in 'user[full_name]', with: 'John Doe'
    fill_in 'user[email_address]', with: 'john@doe.com'
    fill_in 'user[password]', with: 'password'
    click_on 'Continue'
    page.must_have_content 'Is this your full name?'
    page.must_have_content 'What is your team called?'
    fill_in 'user[first_team_name]', with: 'Team Doe'
    click_on 'Continue'
    page.must_have_content 'Invite to Team Doe'
    click_on "I don't want to invite anybody yet"
    assert_current_path team_path(team)
  end

  scenario 'registering without entering team invites to my team' do
    visit register_path
    fill_in 'user[full_name]', with: 'John Doe'
    fill_in 'user[email_address]', with: 'john@doe.com'
    fill_in 'user[password]', with: 'password'
    click_on 'Continue'
    page.must_have_content 'Is this your full name?'
    page.must_have_content 'What is your team called?'
    fill_in 'user[first_team_name]', with: 'Team Doe'
    click_on 'Continue'
    page.must_have_content 'Invite to Team Doe'
    click_on 'Invite'
    assert_current_path team_path(team)
  end

  scenario 'registering should take me through onboarding' do
    visit register_path
    fill_in 'user[full_name]', with: 'John Doe'
    fill_in 'user[email_address]', with: 'john@doe.com'
    fill_in 'user[password]', with: 'password'
    click_on 'Continue'
    page.must_have_content 'Is this your full name?'
    page.must_have_content 'What is your team called?'
    fill_in 'user[first_team_name]', with: 'Team Doe'
    click_on 'Continue'
    page.must_have_content 'Invite to Team Doe'
    fill_in 'Enter email address', with: 'jane@doe.com'
    # TODO make this work
    # within 'div.invitations-panel_potential-invitations' do
    #   page.must_have_content 'jane@doe.com'
    # end
  end
end
