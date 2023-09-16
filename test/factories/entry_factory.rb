FactoryGirl.define do
  factory :entry do
    body  { Faker::Lorem.sentence }
    occurred_on Date.current

    trait :done do
      status 'done'
    end

    trait :goal do
      status 'goal'
    end
  end
end
