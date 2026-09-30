FactoryBot.define do
  factory :subscription do
    transient do
      user { create(:user) }
    end

    customer { association :customer, user: user }
    plan { association :plan, user: user }
    status { :active }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }
  end
end
