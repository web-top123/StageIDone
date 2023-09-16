require 'test_helper'

class FlashbackTest < ActiveSupport::TestCase
  let(:user)      { FactoryGirl.create(:user) }
  let(:team)      { FactoryGirl.create(:team, add_members: [user]) }
  let(:team_test) { FactoryGirl.create(:team) }

  let(:dones_one_day_ago)      { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 1.day.ago.to_date)    }
  let(:dones_one_week_ago)     { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 1.week.ago.to_date)   }
  let(:goals_one_week_ago)     { FactoryGirl.create_list(:entry, 3, :goal, user: user, team: team, occurred_on: 1.week.ago.to_date)   }
  let(:dones_two_weeks_ago)    { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 2.weeks.ago.to_date)  }
  let(:dones_one_month_ago)    { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 1.month.ago.to_date)  }
  let(:dones_two_months_ago)   { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 2.months.ago.to_date) }
  let(:dones_three_months_ago) { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 3.months.ago.to_date) }
  let(:dones_six_months_ago)   { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 6.months.ago.to_date) }
  let(:dones_one_year_ago)     { FactoryGirl.create_list(:entry, 3, :done, user: user, team: team, occurred_on: 1.year.ago.to_date)   }

  before do
    FakeWeb.register_uri(:post, 'https://login.salesforce.com/services/oauth2/token', body: 'ok')
  end


  describe ".generate_flashbacks" do
    before do
      # insert dones for the various dates in the past
      dones_one_day_ago
      dones_one_week_ago
      dones_two_weeks_ago
      dones_one_month_ago
      dones_two_months_ago
      dones_three_months_ago
      dones_six_months_ago
      dones_one_year_ago
    end

    it "only generates flashbacks for one week ago, one month ago, three months ago, six months ago, and one year ago" do
      flashbacks = Flashback.generate_flashbacks(user, team)

      assert_nil     flashbacks.find {|fb| fb.date == 1.day.ago.to_date}
      assert_not_nil flashbacks.find {|fb| fb.date == 1.week.ago.to_date}
      assert_nil     flashbacks.find {|fb| fb.date == 2.weeks.ago.to_date}
      assert_not_nil flashbacks.find {|fb| fb.date == 1.month.ago.to_date}
      assert_nil     flashbacks.find {|fb| fb.date == 2.months.ago.to_date}
      assert_not_nil flashbacks.find {|fb| fb.date == 3.months.ago.to_date}
      assert_not_nil flashbacks.find {|fb| fb.date == 6.months.ago.to_date}
      assert_not_nil flashbacks.find {|fb| fb.date == 1.year.ago.to_date}
    end
  end

  describe ".get" do
    describe "with dones for one day ago and one week ago, and goals for one week ago" do
      let(:april_01_2016) { Time.utc(2016,4,1,16,45,8) }

      before do
        travel_to april_01_2016
        dones_one_day_ago
        dones_one_week_ago
        goals_one_week_ago
      end

      after do
        travel_back
      end

      it "returns a flashback for one week ago with only the dones" do
        flashback = Flashback.get(user, team)
        assert_equal "One week ago", flashback.title
        assert_equal "This is what you got done on this day one week ago, Friday, March 25, 2016", flashback.description
        assert_equal dones_one_week_ago, flashback.entries
      end
    end

    describe "only dones for one day ago" do
      before do
        dones_one_day_ago
      end

      it "returns nil" do
        assert_nil Flashback.get(user, team)
      end
    end
  end
end
