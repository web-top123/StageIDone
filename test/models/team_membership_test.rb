require 'test_helper'

class TeamMembershipTest < ActiveSupport::TestCase
  let(:team_membership) { team_memberships(:user_one_team_one) }
  let(:team_membership_2) { team_memberships(:user_three_team_one) }
  let(:odd_frozen_email_days) { [:monday, :wednesday, :friday, :sunday] }
  let(:user_three_team_one_sample_entry_1) { 
    {
      hash_id: "abc",
      body: "Done one thing",
      user: users(:user_three),
      team: teams(:team_one),
      status: "done",
      occurred_on: Date.current,
    }
  }

  before do
    # We need this since entry creation will trigger POST
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')

    Timecop.freeze(Time.utc(2016,4,1,20,0,0)) # A Friday
  end

  after do
    Timecop.return
  end

  test 'Unsubscribe from all means no subscriptions to anything' do
    team_membership.unsubscribe_from_all!
    assert !team_membership.reminder_days.any?
    assert !team_membership.digest_days.any?
    assert !team_membership.subscribed?
  end

  test "If we're not allowed to send on the friday, it should be monday" do
    team_membership.digest_friday = false
    # Add digest_last_sent_at so the next_digest_time.utc will be based on
    # the Timecop.freeze in 'before do'
    team_membership.update(email_digest_last_sent_at: Time.current - 1.day)

    assert_equal Time.utc(2016,4,4,6,30,0), team_membership.next_digest_time.utc
  end

  test 'If there is no last_sent_at then digest should be the same day' do
    team_membership.update(created_at: Time.now - 1.day)
    assert_equal Time.utc(2016,4,1,6,30,0), team_membership.next_digest_time.utc
  end

  test 'If there is no last_sent_at then reminder should be the next day after created_at' do
    team_membership.update(created_at: Time.now - 1.day)
    assert_equal Time.utc(2016,4,1,15, 0, 0), team_membership.next_reminder_time.utc
  end

  test "If we're not allowed to send on the friday, digest should be monday" do
    team_membership.update(email_digest_last_sent_at: Time.current)
    team_membership.digest_friday = false
    assert_equal Time.utc(2016,4,4,6,30,0), team_membership.next_digest_time.utc
  end

  test "If we're not allowed to send on the friday, reminder should be monday" do
    team_membership.touch(:created_at)
    team_membership.reminder_friday = false
    team_membership.validate!
    assert_equal Time.utc(2016,4,4,15, 0, 0), team_membership.next_reminder_time.utc
  end

  test 'With last_sent set, digest should send the available day (monday)' do
    team_membership.update(created_at: Time.now - 1.day)
    team_membership.email_digest_last_sent_at = Time.utc(2016,4,1,6,30,10) # Friday
    team_membership.validate
    assert_equal Time.utc(2016,4,4,6,30,0), team_membership.next_digest_time.utc
  end

  test 'With last_sent set, reminder should send the available day (monday)' do
    Timecop.freeze(Time.utc(2017,1,1,0,0,0)) # Regardless of what day it is
    team_membership.email_reminder_last_sent_at = Time.utc(2016,4,1,6,30,10) # Friday
    team_membership.validate
    assert_equal Time.utc(2016,4,4,15, 0, 0), team_membership.next_reminder_time.utc
  end

  test 'With last_sent set, digest should send the available day (tuesday)' do
    team_membership.email_digest_last_sent_at = Time.utc(2016,4,4,6,30,10) # Monday
    team_membership.validate
    assert_equal Time.utc(2016,4,5,6,30,0), team_membership.next_digest_time.utc
  end

  test 'With last_sent set, but all days off, next reminder time should be nil' do
    team_membership.unsubscribe_from_all!
    team_membership.email_reminder_last_sent_at = Time.utc(2016,4,4,6,30,10) # Monday
    team_membership.validate
    assert_nil team_membership.next_reminder_time
  end

  test 'With last_sent set, but all days off, next digest time should be nil' do
    team_membership.unsubscribe_from_all!
    team_membership.email_digest_last_sent_at = Time.utc(2016,4,4,6,30,10) # Monday
    team_membership.validate
    assert_nil team_membership.next_digest_time
  end

  test 'TeamMembership.notify_by_digest_email excludes unsubscribed user' do
    team_membership.unsubscribe_from_all!
    assert_not_includes(TeamMembership.notify_by_digest_email, team_membership)
  end

  test 'TeamMembership.notify_by_digest_email excludes inactive user' do
    team_membership.update(removed_at: 1.day.ago)
    assert_not_includes(TeamMembership.notify_by_digest_email, team_membership)
  end

  test 'TeamMembership.notify_by_digest_email excludes users already queued for notification' do
    team_membership.update(digest_status: 'inqueue')
    assert_not_includes(TeamMembership.notify_by_digest_email, team_membership)
  end

  # Ensure that TeamMembership whose last digest email sent resulted in error is still selected
  # for notification
  test 'TeamMembership.notify_by_digest_email includes team_memberships with digest_status in error' do
    team_membership.update(digest_status: 'error')
    assert_includes(TeamMembership.notify_by_digest_email, team_membership)
  end

  test 'TeamMembership.notify_by_reminder_email excludes unsubscribed user' do
    team_membership.unsubscribe_from_all!
    assert_not_includes(TeamMembership.notify_by_reminder_email, team_membership)
  end

  test 'TeamMembership.notify_by_reminder_email excludes inactive user' do
    team_membership.update(removed_at: 1.day.ago)
    assert_not_includes(TeamMembership.notify_by_reminder_email, team_membership)
  end

  test 'TeamMembership.notify_by_reminder_email excludes users already queued for notification' do
    team_membership.update(reminder_status: 'inqueue')
    assert_not_includes(TeamMembership.notify_by_reminder_email, team_membership)
  end

  # Ensure that TeamMembership whose last reminder email sent resulted in error is still selected
  # for notification
  test 'TeamMembership.notify_by_reminder_email includes team_memberships with reminder_status in error' do
    team_membership.update(reminder_status: 'error')
    assert_includes(TeamMembership.notify_by_reminder_email, team_membership)
  end

  test 'TeamMembership.with_inactive_entries does not returns team_membership that have entries in recent week' do
    Entry.create!(user_three_team_one_sample_entry_1)
    assert_not team_membership_2.user.entries.empty?
    assert_not TeamMembership.with_inactive_entries.include?(team_membership_2)
  end

  test 'TeamMembership.with_inactive_entries returns team_membership that has no entry at all' do
    team_membership_2.user.entries.destroy_all
    assert TeamMembership.with_inactive_entries.include?(team_membership_2)
  end

  test 'TeamMembership.with_inactive_entries returns team_membership that have no entries in recent week' do
    team_membership_2.user.entries.destroy_all
    assert team_membership_2.user.entries.empty?
    travel_to(2.week.ago) do
      Entry.create!(user_three_team_one_sample_entry_1)
    end
    assert_equal 1, team_membership_2.user.entries.count
    assert TeamMembership.with_inactive_entries.include?(team_membership_2)
  end

  test 'TeamMembership.with_inactive_entries does not return team_membership created less than a week ago' do
    team_membership_2.user.entries.destroy_all
    team_membership_2.created_at = Time.current
    team_membership_2.save!
    assert team_membership_2.user.entries.empty?
    assert_not TeamMembership.with_inactive_entries.include?(team_membership_2)
  end

  test 'TeamMembership.freeze_email_days(:digest) stores current reminder notification days into #frozen_digest_days' do
    assert_equal [], team_membership.frozen_digest_days

    team_membership.digest_monday = true
    team_membership.digest_tuesday = false
    team_membership.digest_wednesday = true
    team_membership.digest_thursday = false
    team_membership.digest_friday = true
    team_membership.digest_saturday = false
    team_membership.digest_sunday = true
    team_membership.save!

    team_membership.freeze_email_days(:digest)

    assert_equal team_membership.digest_days, team_membership.frozen_email_days(:digest)
  end

  test 'TeamMembership.freeze_email_days(:reminder) stores current reminder notification days into #frozen_reminder_days' do
    assert_equal [], team_membership.frozen_reminder_days

    team_membership.reminder_monday = true
    team_membership.reminder_tuesday = false
    team_membership.reminder_wednesday = true
    team_membership.reminder_thursday = false
    team_membership.reminder_friday = true
    team_membership.reminder_saturday = false
    team_membership.reminder_sunday = true
    team_membership.save!

    team_membership.freeze_email_days(:reminder)

    assert_equal team_membership.reminder_days, team_membership.frozen_email_days(:reminder)
  end

  test 'TeamMembership.unfreeze_email_days(:digest) restores #frozen_digest_days back into digest notification days' do
    team_membership.frozen_digest_days = odd_frozen_email_days
    team_membership.save!

    assert_equal [false, true, true, true, true, true, false], team_membership.digest_days

    team_membership.unfreeze_email_days(:digest)

    assert_equal [true, true, false, true, false, true, false], team_membership.digest_days
    assert_equal team_membership.frozen_digest_days, []
  end

  test 'TeamMembership.unfreeze_email_days(:reminder) restores #frozen_reminder_days back into reminder notification days' do
    team_membership.frozen_reminder_days = odd_frozen_email_days
    team_membership.save!

    assert_equal [false, true, true, true, true, true, false], team_membership.reminder_days

    team_membership.unfreeze_email_days(:reminder)

    assert_equal [true, true, false, true, false, true, false], team_membership.reminder_days
    assert_equal team_membership.frozen_reminder_days, []
  end
end
