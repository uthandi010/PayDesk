FactoryBot.define do
  factory :customer do
    user
    sequence(:email) { |n| "customer#{n}@example.com" }
    name { "Alex Customer" }
  end
end
