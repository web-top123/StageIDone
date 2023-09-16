require 'test_helper'

class ReactionTest < ActiveSupport::TestCase
  let(:user)                   { users(:user_one) }
  let(:entry_for_user)         { entries(:entry_one) }
  let(:entry_for_another_user) { entries(:entry_two) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  test "comment on another user's entry sends an email notification" do
    Reaction.create(user_id: user.id,
                       body: 'ddsds',
              reaction_type: 'comment',
               reactable_id: entry_for_another_user.id,
             reactable_type: 'Entry')
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "comment on your own entry should not send an email notification" do
    Reaction.create( user_id: user.id,
                        body: 'ddsds',
               reaction_type: 'comment',
                reactable_id: entry_for_user.id,
              reactable_type: 'Entry')
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
end
