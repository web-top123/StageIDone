require 'test_helper'

class TeamMembershipsTest < ActiveSupport::TestCase
  let(:team_membership_with_no_entries) { team_memberships(:user_one_team_one) }
  let(:team_membership_with_very_old_entry) { team_memberships(:user_two_team_two) }
  let(:team_membership_with_very_old_entry_and_notifications_off) { team_memberships(:user_one_team_three) }
  let(:team_membership_with_very_old_entry_and_notifications_weekly) { team_memberships(:user_two_team_four) }
  let(:team_membership_with_recent_entry) { team_memberships(:user_three_team_one) }
  let(:team_membership_soft_deleted) { team_memberships(:user_one_team_four) }

  before do
    # We need this since entry creation will trigger POST
    FakeWeb.register_uri(:post, 'https://example.com/some_token/abcdef', body: 'ok')
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')

    # Setup team_memberships of entries
    team_membership_with_no_entries.user.entries.destroy_all
    team_membership_with_very_old_entry.user.entries.destroy_all
    team_membership_with_very_old_entry_and_notifications_off.user.entries.destroy_all
    team_membership_with_recent_entry.user.entries.destroy_all
    team_membership_soft_deleted.user.entries.destroy_all

    team_membership_with_very_old_entry_and_notifications_off.unsubscribe_from_all!
    team_membership_with_very_old_entry_and_notifications_weekly.unsubscribe_from_all!
    team_membership_with_very_old_entry_and_notifications_weekly.update_attributes(digest_monday: true, reminder_tuesday: true)
    team_membership_soft_deleted.destroy!

    occurence_time = 2.week.ago
    team_membership_with_very_old_entry.user.entries.create!(
      hash_id: 'dont_matter',
      body: 'old entry',
      user: team_membership_with_very_old_entry.user,
      team: team_membership_with_very_old_entry.team,
      status: 'done',
      occurred_on: occurence_time,
      created_at: occurence_time,
      updated_at: occurence_time)
    team_membership_with_very_old_entry_and_notifications_off.user.entries.create!(
      hash_id: 'dont_matter',
      body: 'old entry',
      user: team_membership_with_very_old_entry_and_notifications_off.user,
      team: team_membership_with_very_old_entry_and_notifications_off.team,
      status: 'done',
      occurred_on: occurence_time,
      created_at: occurence_time,
      updated_at: occurence_time)
    team_membership_with_very_old_entry_and_notifications_weekly.user.entries.create!(
      hash_id: 'dont_matter',
      body: 'old entry',
      user: team_membership_with_very_old_entry_and_notifications_weekly.user,
      team: team_membership_with_very_old_entry_and_notifications_weekly.team,
      status: 'done',
      occurred_on: occurence_time,
      created_at: occurence_time,
      updated_at: occurence_time)

    occurence_time = 5.day.ago
    team_membership_with_recent_entry.user.entries.create!(
      hash_id: 'dont_matter',
      body: 'new entry',
      user: team_membership_with_recent_entry.user,
      team: team_membership_with_recent_entry.team,
      status: 'done',
      occurred_on: occurence_time,
      created_at: occurence_time,
      updated_at: occurence_time)
  end

  test "Change TeamMembership#status to TeamMembership::STATUS_TYPES[:inactivity] for inactive team memberships" do
    # These by default should be weekdays only notification
    assert_equal [false, true, true, true, true, true, false], team_membership_with_no_entries.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_no_entries.reload.reminder_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_very_old_entry.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_very_old_entry.reload.reminder_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_recent_entry.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_recent_entry.reload.reminder_days
    assert_equal [false, true, true, true, true, true, false], team_membership_soft_deleted.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_soft_deleted.reload.reminder_days

    # These notifications we have customized specifically to none and once a week
    assert_equal [false, false, false, false, false, false, false], team_membership_with_very_old_entry_and_notifications_off.reload.digest_days
    assert_equal [false, false, false, false, false, false, false], team_membership_with_very_old_entry_and_notifications_off.reload.reminder_days
    assert_equal [false, true, false, false, false, false, false], team_membership_with_very_old_entry_and_notifications_weekly.reload.digest_days
    assert_equal [false, false, true, false, false, false, false], team_membership_with_very_old_entry_and_notifications_weekly.reload.reminder_days

    # Originally there should be nothing in the frozen_digest/reminder_days
    assert_equal [], team_membership_with_no_entries.reload.frozen_digest_days
    assert_equal [], team_membership_with_no_entries.reload.frozen_reminder_days
    assert_equal [], team_membership_with_very_old_entry.reload.frozen_digest_days
    assert_equal [], team_membership_with_very_old_entry.reload.frozen_reminder_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_off.reload.frozen_digest_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_off.reload.frozen_reminder_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_weekly.reload.frozen_digest_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_weekly.reload.frozen_reminder_days
    assert_equal [], team_membership_with_recent_entry.reload.frozen_digest_days
    assert_equal [], team_membership_with_recent_entry.reload.frozen_reminder_days
    assert_equal [], team_membership_soft_deleted.reload.frozen_digest_days
    assert_equal [], team_membership_soft_deleted.reload.frozen_reminder_days

    Rake::Task['team_memberships:mark_inactive'].invoke

    # Those marked inactive will have original notifications frozen
    assert_equal [:monday, :tuesday, :wednesday, :thursday, :friday], team_membership_with_no_entries.reload.frozen_digest_days
    assert_equal [:monday, :tuesday, :wednesday, :thursday, :friday], team_membership_with_no_entries.reload.frozen_reminder_days
    assert_equal [:monday, :tuesday, :wednesday, :thursday, :friday], team_membership_with_very_old_entry.reload.frozen_digest_days
    assert_equal [:monday, :tuesday, :wednesday, :thursday, :friday], team_membership_with_very_old_entry.reload.frozen_reminder_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_off.reload.frozen_digest_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_off.reload.frozen_reminder_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_weekly.reload.frozen_digest_days
    assert_equal [], team_membership_with_very_old_entry_and_notifications_weekly.reload.frozen_reminder_days
    assert_equal [], team_membership_with_recent_entry.reload.frozen_digest_days
    assert_equal [], team_membership_with_recent_entry.reload.frozen_reminder_days
    assert_equal [], team_membership_soft_deleted.reload.frozen_digest_days
    assert_equal [], team_membership_soft_deleted.reload.frozen_reminder_days

    # Throttled to once a week email
    assert_equal 1, team_membership_with_no_entries.reload.digest_days.select { |e| e }.size
    assert_equal 1, team_membership_with_no_entries.reload.reminder_days.select { |e| e }.size
    assert_equal 1, team_membership_with_very_old_entry.reload.digest_days.select { |e| e }.size
    assert_equal 1, team_membership_with_very_old_entry.reload.reminder_days.select { |e| e }.size

    # Not throttled since notifications are already off
    assert_equal 0, team_membership_with_very_old_entry_and_notifications_off.reload.digest_days.select { |e| e }.size
    assert_equal 0, team_membership_with_very_old_entry_and_notifications_off.reload.reminder_days.select { |e| e }.size

    # Not throttled (notifications remain) since notifications are already weekly 
    assert_equal [false, true, false, false, false, false, false], team_membership_with_very_old_entry_and_notifications_weekly.reload.digest_days
    assert_equal [false, false, true, false, false, false, false], team_membership_with_very_old_entry_and_notifications_weekly.reload.reminder_days

    # Not throttled since there is activity
    assert_equal [false, true, true, true, true, true, false], team_membership_with_recent_entry.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_with_recent_entry.reload.reminder_days

    # NOTE: Being soft deleted means TeamMembership.all won't pick it up, and won't be marked inactive
    assert_equal [false, true, true, true, true, true, false], team_membership_soft_deleted.reload.digest_days
    assert_equal [false, true, true, true, true, true, false], team_membership_soft_deleted.reload.reminder_days
  end
end
