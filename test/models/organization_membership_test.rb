require 'test_helper'

class OrganizationMembershipTest < ActiveSupport::TestCase
  let(:organization)          { FactoryGirl.create(:organization) }
  let(:user)                  { FactoryGirl.create(:user) }
  let(:stripe_customer)       { '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [{"id":"card_18wKAyJB5ipbWavERyGgiw0G"}], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }' }

  before do
    fake_external_requests(organization.stripe_customer_token, stripe_customer)
  end

  describe '#remove!' do
    let(:organization)            { FactoryGirl.create(:organization, teams: FactoryGirl.create_list(:team, 2)) }
    let(:organization_membership) { OrganizationMembership.create!(role: 'member', organization: organization, user: user) }

    # control organization
    let(:organization_2)            { FactoryGirl.create(:organization, teams: FactoryGirl.create_list(:team, 2)) }
    let(:organization_membership_2) { OrganizationMembership.create!(role: 'member', organization: organization_2, user: user) }

    before do
      fake_external_requests(organization_2.stripe_customer_token, stripe_customer)

      organization_membership

      organization.teams.each do |team|
        team.users << user
      end

      organization_membership_2

      organization_2.teams.each do |team|
        team.users << user
      end
    end

    it 'updates the organization subscription quantity' do
      organization.expects(:update_subscription_quantity).returns(true)
      organization_membership.remove!
    end

    it 'removes the user from the organization' do
      organization_membership.remove!
      assert_equal 0, organization.active_users.count
    end

    it 'removes the user for the organization teams' do
      organization.teams.each do |team|
        assert_equal 1, team.active_users.count
      end

      organization_membership.remove!
      assert_equal 0, organization.active_users.count

      organization.teams.each do |team|
        assert_equal 0, team.active_users.count
      end
    end

    it 'does not affect other organization membership' do
      organization_membership.remove!

      assert_equal 1, organization_2.active_users.count

      organization_2.teams.each do |team|
        assert_equal 1, team.active_users.count
      end
    end
  end

  describe '#join!' do
    context 'with new membership' do
      let(:organization_membership) { OrganizationMembership.new(role: 'member', organization: organization, user: user, removed_at: 1.day.ago) }

      it 'updates the organization subscription quantity' do
        organization.expects(:update_subscription_quantity).returns(true)
        organization_membership.join!
      end

      it 'adds the user to the organization' do
        organization_membership.join!
        assert_equal 1, organization.active_users.count
      end
    end

    context 'with removed membership' do
      let(:organization_membership) { OrganizationMembership.create!(role: 'member', organization: organization, user: user, removed_at: 1.day.ago) }

      before do
        organization_membership
      end

      it 'updates the organization subscription quantity' do
        organization.expects(:update_subscription_quantity).returns(true)
        organization_membership.join!
      end

      it 'adds the user to the organization' do
        organization_membership.join!
        assert_equal 1, organization.active_users.count
      end
    end
  end
end
