require 'test_helper'

feature 'Can create entries' do

  let(:user)          { users(:user_one) }
  let(:another_user)  { users(:user_two) }
  let(:entry)         { entries(:entry_one)}
  let(:team)          { teams(:team_one) }

  before do

    FakeWeb.register_uri(:post, 'http://fakeweb.com', body: 'ok')
 
    visit root_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: 'password'
    click_on 'Login'

  end

  after do
    visit settings_user_path
    click_on 'Logout'
    Timecop.return
  end

  scenario 'notifications and archived notifications are clear' do
    visit notifications_path
    assert page.has_no_content?("has commented on your entry.")
    assert page.has_no_content?("liked your entry.")
    assert page.has_no_content?("liked your comment.")
    assert page.has_no_content?("Your entry was commented")
    assert page.has_no_content?("Your entry received")
    assert page.has_no_content?("Your comment received")
    assert page.has_no_content?("You were mentioned")
  end

  scenario 'notifications added by comment adding' do
    Reaction.create( user_id: another_user.id,
                        body: 'hi there!',
               reaction_type: 'comment',
                reactable_id: entry.id,
              reactable_type: 'Entry')

    visit notifications_path

    assert page.has_content?("has commented on your entry.")
    assert page.has_no_content?("liked your entry.")
    assert page.has_no_content?("liked your comment.")
    assert page.has_no_content?("Your entry was commented")
    assert page.has_no_content?("Your entry received")
    assert page.has_no_content?("Your comment received")
    assert page.has_no_content?("You were mentioned")
  end

  scenario 'notifications added by like adding' do
    Reaction.create( user_id: another_user.id,
               reaction_type: 'like',
                reactable_id: entry.id,
              reactable_type: 'Entry')

    visit notifications_path

    assert page.has_no_content?("has commented on your entry.")
    assert page.has_content?("liked your entry.")
    assert page.has_no_content?("liked your comment.")
    assert page.has_no_content?("Your entry was commented")
    assert page.has_no_content?("Your entry received")
    assert page.has_no_content?("Your comment received")
    assert page.has_no_content?("You were mentioned")
  end

  scenario 'archive notifications' do
    Reaction.create( user_id: another_user.id,
               reaction_type: 'like',
                reactable_id: entry.id,
              reactable_type: 'Entry')

    Reaction.create( user_id: another_user.id,
                        body: "hi there!",
               reaction_type: 'comment',
                reactable_id: entry.id,
              reactable_type: 'Entry')

    visit notifications_path

    click_link('Check All')

    assert page.has_no_content?("has commented on your entry.")
    assert page.has_no_content?("liked your entry.")
    assert page.has_no_content?("liked your comment.")
    assert page.has_no_content?("You were mentioned")

    assert page.has_content?("Your entry was commented")
    assert page.has_content?("Your entry received")
  end

  scenario 'archive notification by viewing' do
    Reaction.create( user_id: another_user.id,
               reaction_type: 'like',
                reactable_id: entry.id,
              reactable_type: 'Entry')

    visit notifications_path

    first(".section-standard a").click

    visit notifications_path
    assert page.has_no_content?("has commented on your entry.")
    assert page.has_no_content?("liked your entry.")
    assert page.has_no_content?("liked your comment.")
    assert page.has_no_content?("You were mentioned")
    assert page.has_no_content?("Your entry was commented")

    assert page.has_content?("Your entry received")

  end
end
