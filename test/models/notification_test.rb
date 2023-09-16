require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  let(:user)            { FactoryGirl.create(:user, full_name: 'Test User') }
  let(:another_user)    { FactoryGirl.create(:user, full_name: 'Second User') }
  let(:team)            { FactoryGirl.create(:team, add_members: [user, another_user]) }
  let(:team_membership) { user.team_memberships.find_by(team_id: team.id) }
  let(:entry_for_user)  { FactoryGirl.create(:entry, :done, user: user, team: team) }

  before do
    # We need this since entry creation will trigger POST
    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
    team_membership.update_attribute(:subscribed_notifications, ['mention', 'like', 'comment'])
  end

  test 'creating notification on mention in entry' do

    Entry.create(user: another_user, team: team, body: "@Test", occurred_on: Date.current, status: 'done')

    assert_equal 1, Mention.count
    assert_equal 1, Notification.count
    assert_equal 0, ArchivedNotification.count

    assert_equal Notification.first.user, user
    assert_equal Notification.first.author, another_user
    assert_equal Notification.first.for_notificable, 'mention_in_entry'
  end

  test 'creating notifications for like' do
    
    Reaction.create( user_id: another_user.id,
                 reaction_type: 'like',
                  reactable_id: entry_for_user.id,
                reactable_type: 'Entry')

    assert_equal 1, Notification.count
    assert_equal 0, ArchivedNotification.count
    assert_equal Notification.last.for_notificable, 'like_on_entry'
  end

  test 'creating notifications for comment with mention' do

    Reaction.create( user_id: another_user.id,
                        body: 'hi there, @test',
               reaction_type: 'comment',
                reactable_id: entry_for_user.id,
              reactable_type: 'Entry')

    assert_equal 1, Notification.count
    assert_equal 0, ArchivedNotification.count

    assert_equal Notification.last.user, user
    assert_equal Notification.last.author, another_user
    assert_equal Notification.last.for_notificable, 'comment_on_entry'
  end

  test 'creating notification in comment' do
    Reaction.create( user_id: another_user.id,
                        body: 'hi there',
               reaction_type: 'comment',
                reactable_id: entry_for_user.id,
              reactable_type: 'Entry')
    assert_equal 1, Notification.count
    assert_equal 0, ArchivedNotification.count

    assert_equal Notification.first.user, user
    assert_equal Notification.first.for_notificable, 'comment_on_entry'
  end

  test 'not creating notification on self-comment' do
    Reaction.create( user_id: user.id,
                        body: 'hi there',
               reaction_type: 'comment',
                reactable_id: entry_for_user.id,
              reactable_type: 'Entry')
    assert_equal 0, Notification.count
    assert_equal 0, ArchivedNotification.count
  end

  test 'check notification' do
    2.times do
      Reaction.create( user_id: another_user.id,
                          body: 'hi there',
                 reaction_type: 'comment',
                  reactable_id: entry_for_user.id,
                reactable_type: 'Entry')
    end

    assert_equal 2, Notification.count
    assert_equal 0, ArchivedNotification.count

    Notification.last.archive!

    assert_equal 1, Notification.count
    assert_equal 1, ArchivedNotification.count
  end

  test 'check all notifications for date' do
    5.times do
      Reaction.create( user_id: another_user.id,
                          body: 'hi there',
                 reaction_type: 'comment',
                  reactable_id: entry_for_user.id,
                reactable_type: 'Entry')
    end

    assert_equal 5, Notification.count
    assert_equal 0, ArchivedNotification.count

    Notification.archive!(user, Reaction.last.created_at, team.id)

    assert_equal 0, Notification.count
    assert_equal 1, ArchivedNotification.count
  end
end
