FactoryGirl.define do
  factory :organization do
    transient do
      add_members []
      add_owners []
    end

    name  { Faker::Company.name }
    stripe_customer_token { Faker::Code.asin }

    after(:create) do |organization, evaluator|
      evaluator.add_members.each do |user|
        OrganizationMembership.create(organization: organization, user: user)
      end

      evaluator.add_owners.each do |user|
        OrganizationMembership.create(organization: organization, user: user, role: 'owner')
      end
    end
  end
end
