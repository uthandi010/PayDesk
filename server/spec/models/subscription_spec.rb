require "rails_helper"

RSpec.describe Subscription do
  it "is invalid when the plan belongs to a different account than the customer" do
    customer = create(:customer)
    plan = create(:plan) # a different, unrelated user

    subscription = build(:subscription, customer: customer, plan: plan)

    expect(subscription).not_to be_valid
    expect(subscription.errors[:plan]).to be_present
  end

  it "is valid when the customer and plan share the same account" do
    user = create(:user)
    customer = create(:customer, user: user)
    plan = create(:plan, user: user)

    subscription = build(:subscription, customer: customer, plan: plan, user: user)

    expect(subscription).to be_valid
  end
end
