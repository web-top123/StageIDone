require 'test_helper'

class ReminderEmailWorkerTest < ActiveSupport::TestCase
  before do
    ActionMailer::Base.deliveries.clear
  end

  test 'sending a digest email' do
    ReminderEmailWorker.perform_async(team_memberships(:user_one_team_one).id)
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
end
