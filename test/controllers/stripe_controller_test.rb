require 'test_helper'

describe StripeController do
  before do
    StripeMock.start
  end

  after do
    StripeMock.stop
  end

  describe 'customer.subscription.updated' do
    let(:organization) { organizations(:paid_organization) }

    describe 'updating to new plan' do
      let(:event) { StripeMock.mock_webhook_event('customer.subscription.updated.to.small.monthly') }

      test 'it updates plan level and plan_interval' do
        post :hook, id: event.id

        organization.reload
        assert_equal 'small', organization.plan_level
        assert_equal 'monthly', organization.plan_interval
      end

      test 'it updates the stripe subscription status' do
        organization.update_column(:stripe_subscription_status, nil)
        post :hook, id: event.id

        assert_equal 'active', organization.reload.stripe_subscription_status
      end
    end

    describe 'updating to invalid plan' do
      let(:event) { StripeMock.mock_webhook_event('customer.subscription.updated.to.unknown.plan') }

      test 'it sends error to sentry' do
        Raven.expects(:capture_message).with("Customer was upgraded to invalid plan",
                                             extra: {
                                               stripe_customer_id: event.data.object.customer,
                                               plan_id: event.data.object.plan.id
                                             })
        post :hook, id: event.id
      end

      test 'it leaves plan level and plan interval unchanged' do
        post :hook, id: event.id

        organization.reload
        assert_equal 'large', organization.plan_level
        assert_equal 'yearly', organization.plan_interval
      end

      test 'it updates stripe subscription status' do
        organization.update_column(:stripe_subscription_status, nil)
        post :hook, id: event.id

        assert_equal 'active', organization.reload.stripe_subscription_status
      end
    end

    describe 'updating status only' do
      let(:event) { StripeMock.mock_webhook_event('customer.subscription.updated.to.past.due') }

      test 'is updates stripe subscription status to past due' do

        post :hook, id: event.id

        assert_equal 'past_due', organization.reload.stripe_subscription_status
      end

      test 'it leaves plan level and plan interval unchanged' do
        post :hook, id: event.id

        organization.reload
        assert_equal 'large', organization.plan_level
        assert_equal 'yearly', organization.plan_interval
      end
    end
  end

  describe 'customer.subscription.created' do
    let(:organization) { organizations(:trial_organization) }

    describe 'creating a new small monthly plan' do
      let(:event) { StripeMock.mock_webhook_event('customer.subscription.created.for.small.monthly') }

      test 'it updates plan level and plan_interval' do
        post :hook, id: event.id

        organization.reload
        assert_equal 'small', organization.plan_level
        assert_equal 'monthly', organization.plan_interval
      end

      test 'it updates the stripe subscription status' do
        organization.update_column(:stripe_subscription_status, nil)
        post :hook, id: event.id

        assert_equal 'active', organization.reload.stripe_subscription_status
      end
    end

    describe 'creating an unknown yearly invoicing plan' do
      let(:event) { StripeMock.mock_webhook_event('customer.subscription.created.for.invoicing.plan') }

      test 'it leaves plan level and plan interval unchanged' do
        post :hook, id: event.id

        organization.reload
        assert_nil organization.plan_level
        assert_nil organization.plan_interval
      end

      test 'it updates the stripe subscription status' do
        organization.update_column(:stripe_subscription_status, nil)
        post :hook, id: event.id

        assert_equal 'active', organization.reload.stripe_subscription_status
      end
    end
  end
end
