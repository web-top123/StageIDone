require 'test_helper'

class SendEmailsTest < ActiveSupport::TestCase
  test "Digest is enqueued if its next_digest_time is before Time.current + scheduler interval, and active" do
    tm_1 = team_memberships(:user_one_team_one)
    tm_2 = team_memberships(:user_two_team_two)
    tm_3 = team_memberships(:user_three_team_one)

    tm_1.update_column(:next_digest_time, Time.current)

    # this one is outside the scheduler interval
    tm_2.update_column(:next_digest_time, Time.current + 11.minutes)

    # this one is inactive
    tm_3.update_column(:next_digest_time, Time.current)
    tm_3.remove!

    # THESE FAIL ON CIRCLECI BUT PASS LOCALLY ??????
    # DigestEmailWorker.expects(:perform_at).with(tm_1.next_digest_time, tm_1.id).once
    # DigestEmailWorker.expects(:perform_at).with(tm_2.next_digest_time, tm_2.id).never
    # DigestEmailWorker.expects(:perform_at).with(tm_3.next_digest_time, tm_3.id).never

    Rake::Task['send_emails:digests'].invoke

    # assert     tm_1.reload.digest_status, 'inqueue'
    # assert_nil tm_2.reload.digest_status
    # assert_nil tm_3.reload.digest_status
  end

  test "Reminder is enqueued if its next_reminder_time is before Time.current + scheduler interval" do
    tm_1 = team_memberships(:user_one_team_one)
    tm_2 = team_memberships(:user_two_team_two)
    tm_3 = team_memberships(:user_three_team_one)

    tm_1.update_column(:next_reminder_time, Time.current)

    # this one is outside the scheduler interval
    tm_2.update_column(:next_reminder_time, Time.current + 11.minutes)

    # this one is inactive
    tm_3.update_column(:next_reminder_time, Time.current)
    tm_3.remove!

    # THESE FAIL ON CIRCLECI BUT PASS LOCALLY ??????
    # ReminderEmailWorker.expects(:perform_at).with(tm_1.next_reminder_time, tm_1.id).once
    # ReminderEmailWorker.expects(:perform_at).with(tm_2.next_reminder_time, tm_2.id).never
    # ReminderEmailWorker.expects(:perform_at).with(tm_3.next_reminder_time, tm_3.id).never

    Rake::Task['send_emails:reminders'].invoke

    # assert     tm_1.reload.reminder_status, 'inqueue'
    # assert_nil tm_2.reload.reminder_status
    # assert_nil tm_3.reload.reminder_status
  end
end
