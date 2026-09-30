FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "owner#{n}@example.com" }
    name { "Jamie Rivera" }
    password { "password123" }
  end
end
