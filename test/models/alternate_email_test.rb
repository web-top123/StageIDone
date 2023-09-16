require 'test_helper'

class AlternateEmailTest < ActiveSupport::TestCase
  let(:user) { users(:user_one) }
  let(:another_user) { users(:user_two) }

  test "verify!" do
    alternate_email = alternate_emails(:unverified)
    alternate_email.verify!
    assert_nil alternate_email.verification_code
    assert_not_nil alternate_email.verified_at
  end

  test ".verified_user with unverified alternate email" do
    alternate_email = alternate_emails(:unverified)
    assert_nil AlternateEmail.verified_user(alternate_email.email_address)
  end

  test ".verified_user with verified alternate email" do
    alternate_email = alternate_emails(:verified)
    assert_equal AlternateEmail.verified_user(alternate_email.email_address), user
  end

  test "validates that email address doesn't already belong to a user" do
    alternate_email = user.alternate_emails.new(email_address: another_user.email_address)
    assert alternate_email.invalid?
  end

  test "validates that email address is not alread assigned to an alternate email" do
    existing_alternate_email = alternate_emails(:verified)
    alternate_email = user.alternate_emails.new(email_address: existing_alternate_email.email_address)
    assert alternate_email.invalid?
  end

  test "is valid if new email address" do
    alternate_email = user.alternate_emails.new(email_address: 'fred@flinstone.com')
    assert alternate_email.valid?
  end

  test "sets verfication code after created and sends email" do
    alternate_email = user.alternate_emails.new(email_address: 'fred@flinstone.com')
    alternate_email.expects(:send_verification_email).returns(true)
    alternate_email.save
    assert_not_nil alternate_email.verification_code
  end
end
