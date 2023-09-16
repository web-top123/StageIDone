FactoryGirl.define do
  factory :user do
    full_name { Faker::Name.name }
    email_address { Faker::Internet.email }
    password "password"
    time_zone "Pacific Time (US & Canada)"

    after(:build) do |u|
      # Should not actually create jobs in all cases
      u.class.skip_callback(:create, :after, :schedule_after_create_jobs)
    end
  end
end
