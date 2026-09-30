module Billing
  # The numbers behind the revenue dashboard. MRR normalizes every active
  # subscription onto a common monthly footing (a yearly plan counts as
  # 1/12th of its price per month) rather than just summing raw plan prices,
  # which is what actually makes "Monthly Recurring Revenue" mean something
  # when a business mixes monthly and yearly plans.
  class DashboardSummary
    def initialize(user, months: 6)
      @user = user
      @months = months
    end

    def call
      {
        mrr_cents: mrr_cents,
        active_subscriptions: user.subscriptions.active.count,
        total_customers: user.customers.count,
        outstanding_invoices: user.invoices.open.count,
        revenue_by_month: revenue_by_month
      }
    end

    private

    attr_reader :user, :months

    def mrr_cents
      user.subscriptions.active.includes(:plan).sum do |sub|
        sub.plan.year? ? (sub.plan.amount_cents / 12.0).round : sub.plan.amount_cents
      end
    end

    def revenue_by_month
      range_start = months.pred.months.ago.beginning_of_month

      paid_totals = user.invoices
                         .where(status: :paid)
                         .where("paid_at >= ?", range_start)
                         .group("strftime('%Y-%m', paid_at)")
                         .sum(:amount_cents)

      (0...months).map do |i|
        month_start = (months - 1 - i).months.ago.beginning_of_month
        key = month_start.strftime("%Y-%m")
        { month: key, amountCents: paid_totals[key] || 0 }
      end
    end
  end
end
