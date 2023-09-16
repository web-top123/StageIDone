require 'test_helper'

class IntegrationLinkTest < ActiveSupport::TestCase
  before do
    FakeWeb.register_uri(:post, "https://login.salesforce.com/services/oauth2/token", body: 'ok')
  end

  describe 'validations' do
    subject { IntegrationLink.new }

    should validate_presence_of(:integration_user)
    should validate_presence_of(:team)

    describe 'slack-poster' do
      let(:team)             { FactoryGirl.create(:team) }
      let(:integration_user) { FactoryGirl.create(:integration_user) }

      subject { IntegrationLink.new(team: team, integration_user: integration_user, integration_type: 'slack-poster') }

      it 'is invalid if meta_data is nil and hence no slack channel' do
        assert subject.invalid?
      end

      it 'is invalid if meta_data has no slack channel' do
        subject.meta_data = {}.to_json
        assert subject.invalid?
      end

      it 'is invalid if meta_data has empty value for slack channel' do
        subject.meta_data = {slack_channel: ""}.to_json
        assert subject.invalid?
      end

      it 'is valid with the presence of a slack channel' do
        subject.meta_data = {slack_channel: "idt"}.to_json
      end
    end

    describe 'slack-incoming' do
      let(:team)             { FactoryGirl.create(:team) }
      let(:integration_user) { FactoryGirl.create(:integration_user) }

      subject { IntegrationLink.new(team: team, integration_user: integration_user, integration_type: 'slack-incoming') }

      it 'is valid' do
        assert subject.valid?
      end
    end

  end

end
