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
    subscription = create(:subscription, user: user, customer: customer,
                           current_period_start: 1.month.ago, current_period_end: 1.minute.ago)

    described_class.new.call(subscription)

    expect(subscription.reload).to be_past_due
    expect(subscription.invoices.sole).to be_open
  end

  it "refuses to renew before the current period has ended, and bills nothing" do
    customer = create(:customer, user: user, email: "regular@example.com")
    subscription = create(:subscription, user: user, customer: customer,
                           current_period_start: Time.current, current_period_end: 1.day.from_now)

    expect { described_class.new.call(subscription) }
      .to raise_error(Billing::SubscriptionRenewer::NotDueError, /before the current period ends/)
    expect(subscription.reload.current_period_end).to be > Time.current
    expect(subscription.invoices).to be_empty
  end

  it "refuses to renew a past_due subscription until its open invoice is handled" do
    customer = create(:customer, user: user, email: "regular@example.com")
    subscription = create(:subscription, user: user, customer: customer, status: :past_due,
                           current_period_start: 1.month.ago, current_period_end: 1.minute.ago)
    create(:invoice, subscription: subscription, status: :open)

    expect { described_class.new.call(subscription) }
      .to raise_error(Billing::SubscriptionRenewer::UnpaidInvoiceError, /open invoice/)
    expect(subscription.invoices.count).to eq(1)
  end

  it "refuses to renew while the subscription still has an open invoice" do
    customer = create(:customer, user: user, email: "regular@example.com")
    subscription = create(:subscription, user: user, customer: customer, status: :active,
                           current_period_start: 1.month.ago, current_period_end: 1.minute.ago)
    create(:invoice, subscription: subscription, status: :open)

    expect { described_class.new.call(subscription) }
      .to raise_error(Billing::SubscriptionRenewer::UnpaidInvoiceError)
  end

  it "renews again once the open invoice has been paid" do
    customer = create(:customer, user: user, email: "regular@example.com")
    subscription = create(:subscription, user: user, customer: customer, status: :past_due,
                           current_period_start: 1.month.ago, current_period_end: 1.minute.ago)
    invoice = create(:invoice, subscription: subscription, status: :open)
    Billing::InvoiceCharger.new.call(invoice)

    described_class.new.call(subscription)

    expect(subscription.reload).to be_active
    expect(subscription.invoices.count).to eq(2)
    expect(subscription.invoices).to all(be_paid)
  end
end
