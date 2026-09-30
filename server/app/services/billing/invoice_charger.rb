module Billing
  # Attempts to charge a single open invoice through a payment gateway and
  # records what happened. This is the one place that talks to a gateway -
  # controllers never call a gateway directly, and always go through this so
  # an invoice's status, its subscription's status, and its Payment history
  # move together and can never drift apart.
  class InvoiceCharger
    Result = Struct.new(:invoice, :charge_result, keyword_init: true) do
      def success?
        charge_result.success?
      end
    end

    def initialize(gateway: Rails.application.config.x.payment_gateway)
      @gateway = gateway
    end

    def call(invoice)
      raise ArgumentError, "invoice must be open to charge, was #{invoice.status}" unless invoice.open?

      charge_result = @gateway.charge(amount_cents: invoice.amount_cents, customer: invoice.customer)

      ActiveRecord::Base.transaction do
        invoice.payments.create!(
          amount_cents: invoice.amount_cents,
          status: charge_result.success? ? :succeeded : :failed,
          gateway_reference: charge_result.reference,
          failure_reason: charge_result.failure_reason
        )

        subscription = invoice.subscription

        if charge_result.success?
          invoice.update!(status: :paid, paid_at: Time.current)
          subscription.update!(status: :active) if subscription.past_due?
        else
          subscription.update!(status: :past_due) unless subscription.canceled?
        end
      end

      Result.new(invoice: invoice.reload, charge_result: charge_result)
    end
  end
end
