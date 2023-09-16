require 'test_helper'

feature 'Organization Memberships' do
  let(:owner)          { FactoryGirl.create(:user) }
  let(:admin)          { FactoryGirl.create(:user) }
  let(:member)         { FactoryGirl.create(:user) }

  let(:organization)   { FactoryGirl.create(:organization, stripe_customer_token: "cus_8lopLcQR1KvIgb") }
  let(:team)           { FactoryGirl.create(:team, organization: organization) }

  let(:owner_membership)  { organization.organization_memberships.create!(role: 'owner',  user: owner) }
  let(:admin_membership)  { organization.organization_memberships.create!(role: 'admin',  user: admin) }
  let(:member_membership) { organization.organization_memberships.create!(role: 'member',  user: member) }

  let(:stripe_customer) { '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [{"id":"card_18wKAyJB5ipbWavERyGgiw0G"}], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }' }

  before do
    fake_external_requests

    # minitest doesn't have let! :-(
    owner_membership
    admin_membership
    member_membership

    team.users << owner
    team.users << admin
    team.users << member
  end

  after do
    logout
  end

  scenario "an owner can remove a member from the organization" do
    login_as owner

    visit team_team_memberships_path(team)

    # all three users are members of the team
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.must_have_content member.full_name
    end

    visit organization_organization_memberships_path(organization)

    # all three users are members of the organization
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.must_have_content member.full_name
    end

    find(:xpath, "//a[@href='#{organization_organization_membership_path(organization, member_membership)}']").click
    page.must_have_content "#{member.full_name} has been removed."

    # member has been removed from organization
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.assert_no_text member.full_name
    end

    visit team_team_memberships_path(team)

    # member has been removed from team
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.assert_no_text member.full_name
    end
  end

  scenario "an owner cannot remove themselves from the organization" do
    login_as owner

    visit organization_organization_memberships_path(organization)

    # all three users are members of the organization
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.must_have_content member.full_name
    end

    # no remove button for self
    page.assert_no_selector(:xpath, "//a[@href='#{organization_organization_membership_path(organization, owner_membership)}']")

    # remove buttons for admin and member
    page.assert_selector(:xpath, "//a[@href='#{organization_organization_membership_path(organization, admin_membership)}']")
    page.assert_selector(:xpath, "//a[@href='#{organization_organization_membership_path(organization, member_membership)}']")
  end

  scenario "an admin cannot remove a member from the organization" do
    login_as admin

    visit organization_organization_memberships_path(organization)

    # all three users are members of the organization
    within '.list-members' do
      page.must_have_content owner.full_name
      page.must_have_content admin.full_name
      page.must_have_content member.full_name
    end

    page.assert_no_selector(:xpath, "//a[@href='#{organization_organization_membership_path(organization, member_membership)}']")
  end
end
