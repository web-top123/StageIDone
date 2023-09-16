require 'test_helper'

class TeamTest < ActiveSupport::TestCase

  describe 'deleting a team with invitations' do
    let(:team_one) { FactoryGirl.create(:team) }
    let(:team_two) { FactoryGirl.create(:team) }

    let(:invite_to_team_one_only)    { FactoryGirl.create(:invitation, team_ids: [team_one.id])}
    let(:invite_to_team_one_and_two) { FactoryGirl.create(:invitation, team_ids: [team_one.id, team_two.id])}

    before do
      invite_to_team_one_only # let!
      invite_to_team_one_and_two # let!
    end


    it "destroys invitation if it's only for that the deleted team" do
      team_one.destroy
      assert_nil Invitation.find_by_id(invite_to_team_one_only.id)
    end

    it "removes the team_id the deleted team if invitation includes other teams" do
      team_one.destroy
      assert_equal [team_two.id], invite_to_team_one_and_two.reload.team_ids
    end
  end

end
