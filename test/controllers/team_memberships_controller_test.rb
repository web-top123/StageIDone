require 'test_helper'

describe TeamMembershipsController do
  before do
    customer_data = '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }'
    FakeWeb.register_uri(:get,  'https://api.stripe.com/v1/customers/cus_8lopLcQR1KvIgb', body: customer_data)
    login_user(users(:user_one))
  end

  let(:team_membership) do
    tm = team_memberships(:user_one_team_one)
    tm.validate
    tm
  end

  test 'can update membership settings' do
    assert_difference 'TeamMembership.count', 0 do
      # Update can only update your own membership
      put :update, id: team_membership.id, team_id: teams(:team_one).hash_id,
        team_membership: {

          reminder_sunday: true,
          reminder_monday: true,
          reminder_tuesday: true,
          reminder_wednesday: false,
          reminder_thursday: false,
          reminder_friday: false,
          reminder_saturday: false,

          digest_sunday: false,
          digest_monday: true,
          digest_tuesday: true,
          digest_wednesday: false,
          digest_thursday: false,
          digest_friday: false,
          digest_saturday: false,
          email_digest_seconds_since_midnight: 0,
          email_reminder_seconds_since_midnight: 1,
        }
    end
    team_membership.reload
    assert_equal [true,true,true,false,false,false,false], team_membership.reminder_days
    assert_equal [false,true,true,false,false,false,false], team_membership.digest_days
    assert_equal 0, team_membership.email_digest_seconds_since_midnight
    assert_equal 1, team_membership.email_reminder_seconds_since_midnight
  end

  test 'can view membership notifications settings' do
    get :notifications, id: team_membership.id, team_id: teams(:team_one).hash_id
    assert_response :success
  end

  test 'can save membership notifications settings' do
    put :notifications_save, id: team_membership.id, team_id: teams(:team_one).hash_id,
      team_membership: {subscribed_notifications: ['comment', 'mention']}
    assert_response :success
    assert_equal ['comment', 'mention'], team_membership.subscribed_notifications
  end

  test "should unsubscribe digests notification" do
    assert team_membership.digest_subscribed?

    get :unsubscribe_digests, { id: team_membership.id, team_id: team_membership.team.hash_id }

    assert_not team_membership.reload.digest_subscribed?
  end

  test "should unsubscribe reminders notification" do
    assert team_membership.reminder_subscribed?

    get :unsubscribe_reminders, { id: team_membership.id, team_id: team_membership.team.hash_id }

    assert_not team_membership.reload.reminder_subscribed?
  end

  test "should unsubscribe comments notification" do
    assert team_membership.
      subscribed_notifications.
        include?('comment')

    get :unsubscribe_comments_notification, { id: team_membership.id, team_id: team_membership.team.hash_id }

    assert_not team_membership.reload.subscribed_notifications.include?('comment')
  end

  test "should unsubscribe mentions notification" do
    assert team_membership.
      subscribed_notifications.
        include?('mention')

    get :unsubscribe_mentions_notification, { id: team_membership.id, team_id: team_membership.team.hash_id }

    assert_not team_membership.reload.subscribed_notifications.include?('mention')
  end
end
