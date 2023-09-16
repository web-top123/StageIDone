require 'test_helper'

class IdtIntercomConcernsTest < ActiveSupport::TestCase
  before do
    FakeWeb.register_uri(:post, "https://login.salesforce.com/services/oauth2/token", body: 'ok')
  end

  describe 'Users' do
    describe 'creating a new user' do
      let(:user)  { FactoryGirl.build(:user) }

      it 'immediately sends to Intercom rather than queueing' do
        user.expects(:send_to_intercom)
        user.save!
        refute IntercomQueue.exists?(user_id: user.id)
      end
    end

    describe 'updating a user' do
      let(:user)  { FactoryGirl.create(:user) }

      before do
        user # let!
        IntercomQueue.delete_all # clear queue
      end

      it 'updating email address adds a record to Intercom Queue for the user' do
        user.update_attribute(:email_address, 'benji@indonethis.com')
        assert IntercomQueue.exists?(user_id: user.id)
      end

      it 'updating full name adds a record to Intercom Queue for the user' do
        user.update_attribute(:full_name, 'Benjamin Franklin')
        assert IntercomQueue.exists?(user_id: user.id)
      end

      it 'updating phone number adds a record to Intercom Queue for the user' do
        user.update_attribute(:phone_number, '+1-555-222-9229')
        assert IntercomQueue.exists?(user_id: user.id)
      end

      it 'updating nickname does not add a record to Intercom Queue for the user' do
        user.update_attribute(:nickname, 'benji')
        refute IntercomQueue.exists?(user_id: user.id)
      end
    end

  end

  describe 'Entries' do
    let(:team)  { FactoryGirl.create(:team, add_members: [user]) }
    let(:entry) { FactoryGirl.build(:entry, user: user, team: team, occurred_on: Date.current) }

    before do
      user # let!
      team # let!
      IntercomQueue.delete_all # clear queue
    end

    describe 'creating a new entry for new user' do
      let(:user)  { FactoryGirl.create(:user) }

      it 'adds a record to Intercom Queue for the user' do
        entry.save!
        assert IntercomQueue.exists?(user_id: user.id)
      end
    end

    describe 'creating a new entry for user created 15 days ago' do
      let(:user)  { FactoryGirl.create(:user, created_at: 15.days.ago) }

      it 'does not add a record to Intercom Queue for the user' do
        entry.save!
        refute IntercomQueue.exists?(user_id: user.id)
      end
    end
  end

  describe 'Reactions' do
    let(:team)     { FactoryGirl.create(:team, add_members: [user]) }
    let(:entry)    { FactoryGirl.create(:entry, user: user, team: team, occurred_on: Date.current) }
    let(:reaction) { FactoryGirl.create(:reaction, :comment, reactable: entry, user: user) }

    before do
      entry # let!
      IntercomQueue.delete_all # clear queue
    end

    describe 'creating a new entry reaction for new user' do
      let(:user)  { FactoryGirl.create(:user) }

      it 'adds a record to Intercom Queue for the user' do
        reaction.save!
        assert IntercomQueue.exists?(user_id: user.id)
      end
    end

    describe 'creating a new entry reaction for user created 15 days ago' do
      let(:user)  { FactoryGirl.create(:user, created_at: 15.days.ago) }

      it 'does not add a record to Intercom Queue for the user' do
        reaction.save!
        refute IntercomQueue.exists?(user_id: user.id)
      end
    end
  end

  describe 'Invitations' do
    let(:user)         { FactoryGirl.create(:user) }
    let(:organization) { FactoryGirl.create(:organization) }
  
    before do
      fake_external_requests(organization.stripe_customer_token)
      user # let!
      IntercomQueue.delete_all # clear queue
    end

    describe 'creating a new invitation' do
      let(:invitation) { Invitation.new(organization: organization, sender: user, email_address: 'benji@idonethis.com') }

      it 'adds a record to Intercom Queue for the user' do
        invitation.save!
        assert IntercomQueue.exists?(user_id: user.id)
      end
    end

    describe 'redeeming an invitation' do
      let(:benji)      { FactoryGirl.create(:user, email_address: 'benji@idonethis.com')}
      let(:invitation) { Invitation.create!(organization: organization, sender: user, email_address: 'benji@idonethis.com') }

      before do
        benji #let
        invitation #let
      end

      it 'adds a record to Intercom Queue for the user' do
        invitation.redeem_invitation!
        assert IntercomQueue.exists?(user_id: benji.id)
      end
    end
  end

  describe 'Integration Users' do
    let(:user)             { FactoryGirl.create(:user) }
    let(:integration_user) { FactoryGirl.build(:integration_user, user: user) }
  
    before do
      user # let!
      IntercomQueue.delete_all # clear queue
    end

    describe 'creating a new integration user' do
      it 'adds a record to Intercom Queue for the user' do
        integration_user.save!
        assert IntercomQueue.exists?(user_id: user.id)
      end
    end
  end

  describe 'Organizations' do
    let(:owner_1)         { FactoryGirl.create(:user) }
    let(:owner_2)         { FactoryGirl.create(:user) }
    let(:member)          { FactoryGirl.create(:user) }
    let(:organization)    { FactoryGirl.create(:organization, add_owners: [owner_1, owner_2], add_members: [member], stripe_customer_token: "cus_8lopLcQR1KvIgb") }
    
    before do
      fake_external_requests
      IntercomQueue.delete_all # clear queue
    end

    describe 'subscription changes' do
      it 'adds records to Intercom Queue for the owners' do
        organization.update_attributes!(plan_level: 'medium', plan_interval: 'monthly')
        assert IntercomQueue.exists?(user_id: owner_1.id)
        assert IntercomQueue.exists?(user_id: owner_2.id)
      end
    end
  end
end
