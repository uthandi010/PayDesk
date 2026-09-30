module Billing
  # Creates a subscription and immediately bills its first period. This is
  # the moment a real system would hand off to a scheduler for every future
  # renewal; here that "next tick" is exposed explicitly as
  # Billing::SubscriptionRenewer so the recurring-billing behavior can be
  # demonstrated and tested without a background job runner.
  class SubscriptionCreator
    def initialize(charger: InvoiceCharger.new)
      @charger = charger
    end

    def call(customer:, plan:)
      subscription = nil
      invoice = nil

      ActiveRecord::Base.transaction do
        now = Time.current
        subscription = Subscription.create!(
          customer: customer,
          plan: plan,
          status: :active,
          current_period_start: now,
          current_period_end: now + plan.period_length
        )

        invoice = subscription.invoices.create!(
          amount_cents: plan.amount_cents,
          status: :open,
          due_date: now
        )
      end

      @charger.call(invoice)
      subscription.reload
    end
  end
end
