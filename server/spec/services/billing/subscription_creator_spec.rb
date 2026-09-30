require "rails_helper"

RSpec.describe Billing::SubscriptionCreator do
  let(:user) { create(:user) }

  it "creates an active subscription and an immediately-paid invoice for a good customer" do
    customer = create(:customer, user: user, email: "regular@example.com")
    plan = create(:plan, user: user, amount_cents: 1500, interval: :month)

    subscription = described_class.new.call(customer: customer, plan: plan)

    expect(subscription).to be_active
    expect(subscription.current_period_end).to be_within(1.second).of(subscription.current_period_start + 1.month)

    invoice = subscription.invoices.sole
    expect(invoice).to be_paid
    expect(invoice.amount_cents).to eq(1500)
  end

  it "advances a yearly plan's period by a year" do
    customer = create(:customer, user: user, email: "regular@example.com")
    plan = create(:plan, :yearly, user: user)

    subscription = described_class.new.call(customer: customer, plan: plan)

    expect(subscription.current_period_end).to be_within(1.second).of(subscription.current_period_start + 1.year)
  end

  it "still creates the subscription when the first charge is declined, but leaves it past_due" do
    customer = create(:customer, user: user, email: "shopper@declined.test")
    plan = create(:plan, user: user)

    subscription = described_class.new.call(customer: customer, plan: plan)

    expect(subscription).to be_past_due
    expect(subscription.invoices.sole).to be_open
  end

  it "rejects a plan that belongs to a different account than the customer" do
    customer = create(:customer, user: user)
    other_users_plan = create(:plan)

    expect {
      described_class.new.call(customer: customer, plan: other_users_plan)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
