if ENV['COVERAGE_REPORTER'] && ENV['COVERAGE_REPORTER'].to_s == 'code_climate'
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start 'rails'
end

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "mocha/mini_test"
require "minitest/rails/capybara"

# Sidekiq stuff
require "sidekiq/testing"
Sidekiq::Testing.inline!

# Improved Minitest output (color and progress bar)
require "minitest/reporters"
Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new,
  ENV,
  Minitest.backtrace_filter)

# Capybara and poltergeist integration
require "capybara/rails"
require 'capybara/email'
require "capybara/poltergeist"
Capybara.javascript_driver = :poltergeist

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Email::DSL
end

# See: https://gist.github.com/mperham/3049152
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
  end
end
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

require 'fakeweb'
FakeWeb.allow_net_connect = %r[^https?://(127.0.0.1|codeclimate.com)+]

require "support/test_password_helper"
ActiveRecord::FixtureSet.context_class.send :include, TestPasswordHelper

StripeMock.webhook_fixture_path = './test/fixtures/stripe_webhooks/'

require "support/test_login_helper"
class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  include TestPasswordHelper
  include TestLoginHelper
  include Sorcery::TestHelpers::Rails::Controller
  fixtures :all

  def setup
    stub_intercom_requests!
  end
end

# Runs assert_difference with a number of conditions and varying difference
# counts.
#
# Call as follows:
#
# assert_differences([['Model1.count', 2], ['Model2.count', 3]])
#
def assert_differences(expression_array, message = nil, &block)
  b = block.send(:binding)
  before = expression_array.map { |expr| eval(expr[0], b) }

  yield

  expression_array.each_with_index do |pair, i|
    e = pair[0]
    difference = pair[1]
    error = "#{e.inspect} didn't change by #{difference}"
    error = "#{message}\n#{error}" if message
    assert_equal(before[i] + difference, eval(e, b), error)
  end
end

def stub_intercom_requests!
  IntercomApi.stubs(:upsert_user)
end

def fake_external_requests(stripe_customer_token='cus_8lopLcQR1KvIgb', stripe_customer=mock_stripe_customer)
  raise "Stripe Customer Token and Stripe Customer mock required" unless stripe_customer_token.present? && stripe_customer.present?
  FakeWeb.register_uri(:post, "https://login.salesforce.com/services/oauth2/token", body: 'ok')
  FakeWeb.register_uri(:post, "https://api.stripe.com/v1/customers/#{stripe_customer_token}", body: stripe_customer)
  FakeWeb.register_uri(:get,  "https://api.stripe.com/v1/customers/#{stripe_customer_token}", body: stripe_customer)
  FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/plans', body: '{}') # create the default plans
  FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/subscriptions/sub_8lopgdmOmdAiqd', body: '{}')
  FakeWeb.register_uri(:post, 'https://api.stripe.com/v1/subscriptions', body: '{}')
  FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
end

def mock_stripe_customer
  '{ "id": "cus_8lopLcQR1KvIgb", "object": "customer", "account_balance": 0, "created": 1467816001, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "livemode": false, "metadata": { }, "shipping": null, "sources": { "object": "list", "data": [{"id":"card_18wKAyJB5ipbWavERyGgiw0G"}], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_8lopLcQR1KvIgb/sources" }, "subscriptions": { "object": "list", "data": [ { "id": "sub_8lopgdmOmdAiqd", "object": "subscription", "application_fee_percent": null, "cancel_at_period_end": false, "canceled_at": null, "created": 1467816001, "current_period_end": 1469025601, "current_period_start": 1467816001, "customer": "cus_8lopLcQR1KvIgb", "discount": null, "ended_at": null, "livemode": false, "metadata": { }, "plan": { "id": "large-monthly-v1", "object": "plan", "amount": 3000, "created": 1459424200, "currency": "usd", "interval": "month", "interval_count": 1, "livemode": false, "metadata": { }, "name": "Large monthly ", "statement_descriptor": null, "trial_period_days": 3 }, "quantity": 1, "start": 1467816001, "status": "trialing", "tax_percent": null, "trial_end": 1469025601, "trial_start": 1467816001 } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_8lopLcQR1KvIgb/subscriptions" } }'
end

# Because we don't have rspec and full feature tests I'm putting this in here
# I'm sure there's a better way to do it but Rails testing is a cess pool of crap
def js
  Capybara.current_driver = Capybara.javascript_driver
  yield
  Capybara.current_driver = Capybara.default_driver
end

