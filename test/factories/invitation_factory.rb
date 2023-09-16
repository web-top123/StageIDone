FactoryGirl.define do
  factory :invitation do
    transient do
      teams []
    end

    invitation_code { Faker::Code.asin }
    email_address { Faker::Internet.email }
    organization
  end
end
