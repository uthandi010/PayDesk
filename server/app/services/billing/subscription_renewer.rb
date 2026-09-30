module Billing
  # Advances a subscription into its next billing period and bills it. In
  # production this would run as a scheduled job for every subscription
  # whose current_period_end has passed; here it's exposed as an explicit
  # action (POST /api/subscriptions/:id/renew) so the recurring part of
  # "recurring billing" is actually reachable without a job scheduler.
  class SubscriptionRenewer
    class AlreadyCanceledError < StandardError; end

    def initialize(charger: InvoiceCharger.new)
      @charger = charger
    end

    def call(subscription)
      raise AlreadyCanceledError, "cannot renew a canceled subscription" if subscription.canceled?

      invoice = nil
      plan = subscription.plan

      ActiveRecord::Base.transaction do
        new_start = subscription.current_period_end
        subscription.update!(current_period_start: new_start, current_period_end: new_start + plan.period_length)

        invoice = subscription.invoices.create!(
          amount_cents: plan.amount_cents,
          status: :open,
          due_date: new_start
        )
      end

      @charger.call(invoice)
      subscription.reload
    end
  end
end
