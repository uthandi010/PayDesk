FactoryBot.define do
  factory :plan do
    user
    name { "Pro" }
    amount_cents { 2900 }
    interval { :month }
    active { true }

    trait :yearly do
      interval { :year }
      amount_cents { 29000 }
    end
  end
end
