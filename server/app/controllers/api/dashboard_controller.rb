module Api
  class DashboardController < ApplicationController
    before_action :authenticate_user!

    def summary
      data = Billing::DashboardSummary.new(current_user).call
      render json: {
        mrrCents: data[:mrr_cents],
        activeSubscriptions: data[:active_subscriptions],
        totalCustomers: data[:total_customers],
        outstandingInvoices: data[:outstanding_invoices],
        revenueByMonth: data[:revenue_by_month]
      }
    end
  end
end
