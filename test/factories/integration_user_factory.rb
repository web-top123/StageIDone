FactoryGirl.define do
  factory :integration_user do
    user
    oauth_uid { Faker::Code.asin }
    oauth_access_token { Faker::Code.asin }
  end
end
