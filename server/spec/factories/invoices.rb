FactoryBot.define do
  factory :invoice do
    subscription
    amount_cents { 2900 }
    status { :open }
    due_date { Time.current }
  end
end
