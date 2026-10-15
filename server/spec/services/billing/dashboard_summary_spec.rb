require "rails_helper"

RSpec.describe Billing::DashboardSummary do
  let(:user) { create(:user) }

  it "sums active subscriptions onto a common monthly footing for MRR" do
    monthly_plan = create(:plan, user: user, amount_cents: 3000, interval: :month)
    yearly_plan = create(:plan, :yearly, user: user, amount_cents: 12000, interval: :year)

    create(:subscription, user: user, plan: monthly_plan, status: :active)
    create(:subscription, user: user, plan: yearly_plan, status: :active)
    # A canceled subscription must not count toward MRR at all.
    create(:subscription, user: user, plan: monthly_plan, status: :canceled)

    summary = described_class.new(user).call

    # 3000 (monthly) + 12000/12 = 1000 (yearly, normalized to monthly) = 4000
    expect(summary[:mrr_cents]).to eq(4000)
    expect(summary[:active_subscriptions]).to eq(2)
  end

  it "counts customers and open invoices scoped to the current user only" do
    other_user = create(:user)

    my_subscription = create(:subscription, user: user)
    create(:invoice, subscription: my_subscription, status: :open)

    other_subscription = create(:subscription, user: other_user)
    create(:invoice, subscription: other_subscription, status: :open)

    summary = described_class.new(user).call

    expect(summary[:total_customers]).to eq(1)
    expect(summary[:outstanding_invoices]).to eq(1)
  end

  it "zero-fills every month in the window, even ones with no paid invoices" do
    subscription = create(:subscription, user: user)
    create(:invoice, subscription: subscription, status: :paid, paid_at: Time.current, amount_cents: 500)

    summary = described_class.new(user, months: 3).call

    expect(summary[:revenue_by_month].size).to eq(3)
    expect(summary[:revenue_by_month].last[:amountCents]).to eq(500)
    expect(summary[:revenue_by_month].first[:amountCents]).to eq(0)
    expect(summary[:revenue_by_month].map { |m| m[:month] }).to eq(summary[:revenue_by_month].map { |m| m[:month] }.sort)
  end

  it "sums paid invoices into the month they were paid in and ignores ones before the window" do
    subscription = create(:subscription, user: user)
    this_month = Time.current.beginning_of_month + 1.day
    last_month = this_month - 1.month
    create(:invoice, subscription: subscription, status: :paid, paid_at: this_month, amount_cents: 100)
    create(:invoice, subscription: subscription, status: :paid, paid_at: this_month + 1.hour, amount_cents: 200)
    create(:invoice, subscription: subscription, status: :paid, paid_at: last_month, amount_cents: 400)
    create(:invoice, subscription: subscription, status: :paid, paid_at: this_month - 3.months, amount_cents: 800)

    summary = described_class.new(user, months: 2).call

    expect(summary[:revenue_by_month]).to eq([
      { month: last_month.strftime("%Y-%m"), amountCents: 400 },
      { month: this_month.strftime("%Y-%m"), amountCents: 300 }
    ])
  end

  it "doesn't rely on database-specific date functions" do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.new(user).call
    end

    expect(queries.join("\n")).not_to match(/strftime|date_trunc|to_char/i)
  end

  it "excludes invoices that are open or void from monthly revenue" do
    subscription = create(:subscription, user: user)
    create(:invoice, subscription: subscription, status: :open, amount_cents: 999)
    create(:invoice, subscription: subscription, status: :void, amount_cents: 999)

    summary = described_class.new(user, months: 1).call

    expect(summary[:revenue_by_month].sole[:amountCents]).to eq(0)
  end
end
