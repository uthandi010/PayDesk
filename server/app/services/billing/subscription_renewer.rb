module Billing
  # Advances a subscription into its next billing period and bills it. In
  # production this would run as a scheduled job for every subscription
  # whose current_period_end has passed; here it's exposed as an explicit
  # action (POST /api/subscriptions/:id/renew) so the recurring part of
  # "recurring billing" is actually reachable without a job scheduler.
  #
  # A renewal is refused (with a RenewalError) unless the current period
  # has actually ended, and while the subscription is past_due or still has
  # an open invoice - that invoice has to be paid (retry / public link) or
  # the subscription canceled first, rather than piling up unpaid periods.
  class SubscriptionRenewer
    class RenewalError < StandardError; end
    class AlreadyCanceledError < RenewalError; end
    class NotDueError < RenewalError; end
    class UnpaidInvoiceError < RenewalError; end

    def initialize(charger: InvoiceCharger.new)
      @charger = charger
    end

    def call(subscription)
      invoice = nil
      plan = subscription.plan

      # Locked so two concurrent renew requests can't both advance the period.
      subscription.with_lock do
        ensure_renewable!(subscription)

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

    private

    def ensure_renewable!(subscription)
      raise AlreadyCanceledError, "cannot renew a canceled subscription" if subscription.canceled?

      if subscription.past_due? || subscription.invoices.open.exists?
        raise UnpaidInvoiceError,
              "cannot renew while an invoice is unpaid - pay or retry the open invoice first"
      end

      if subscription.current_period_end > Time.current
        raise NotDueError,
              "cannot renew before the current period ends (#{subscription.current_period_end.iso8601})"
      end
    end
  end
end
