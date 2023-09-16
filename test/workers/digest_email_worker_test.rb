require 'test_helper'

class DigestEmailWorkerTest < ActiveSupport::TestCase
  before do
    ActionMailer::Base.deliveries.clear
  end

  test 'sending a digest email' do
    DigestEmailWorker.perform_async(team_memberships(:user_one_team_one).id)
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
end
