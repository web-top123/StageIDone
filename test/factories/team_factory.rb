FactoryGirl.define do
  factory :team do
    transient do
      add_members []
    end

    name  { Faker::Team.name }
    organization

    after(:create) do |team, evaluator|
      evaluator.add_members.each do |user|
        TeamMembership.create(team: team, user: user)
      end
    end

  end
end
