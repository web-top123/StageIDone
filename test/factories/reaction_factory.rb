FactoryGirl.define do
  factory :reaction do
    body  { Faker::Lorem.sentence }

    trait :comment do
      reaction_type 'comment'
    end

    trait :like do
      reaction_type 'like'
    end
  end
end
