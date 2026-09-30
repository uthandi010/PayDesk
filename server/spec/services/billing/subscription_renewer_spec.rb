require "rails_helper"

RSpec.describe Billing::SubscriptionRenewer do
  let(:user) { create(:user) }

  it "advances the period forward by the plan's interval and bills the new period" do
    customer = create(:customer, user: user, email: "regular@example.com")
    plan = create(:plan, user: user, amount_cents: 2000, interval: :month)
    subscription = create(:subscription, user: user, customer: customer, plan: plan,
                           current_period_start: 1.month.ago, current_period_end: Time.current)
    old_end = subscription.current_period_end

    described_class.new.call(subscription)
    subscription.reload

    expect(subscription.current_period_start).to be_within(1.second).of(old_end)
    expect(subscription.current_period_end).to be_within(1.second).of(old_end + 1.month)
    expect(subscription.invoices.count).to eq(1)
    expect(subscription.invoices.sole).to be_paid
  end

  it "raises when trying to renew a canceled subscription" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer, status: :canceled)

    expect { described_class.new.call(subscription) }
      .to raise_error(Billing::SubscriptionRenewer::AlreadyCanceledError)
  end

  it "marks the subscription past_due (without destroying the renewal) when the charge is declined" do
    customer = create(:customer, user: user, email: "shopper@declined.test")
    subscription = create(:subscription, user: user, customer: customer)

    described_class.new.call(subscription)

    expect(subscription.reload).to be_past_due
    expect(subscription.invoices.sole).to be_open
  end
end
