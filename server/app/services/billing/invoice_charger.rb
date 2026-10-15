module Billing
  # Attempts to charge a single open invoice through a payment gateway and
  # records what happened. This is the one place that talks to a gateway -
  # controllers never call a gateway directly, and always go through this so
  # an invoice's status, its subscription's status, and its Payment history
  # move together and can never drift apart.
  #
  # The invoice row is locked for the whole attempt and its status is
  # re-checked under that lock, so two concurrent pay/retry requests for the
  # same invoice are serialized: the second one sees the invoice already paid
  # and is refused instead of charging the customer a second time. Each
  # attempt also carries a stable idempotency key, so a gateway that honours
  # one won't double-charge if the same attempt is replayed after a crash.
  class InvoiceCharger
    # Subclasses ArgumentError so existing callers that rescue ArgumentError
    # keep working.
    class NotChargeableError < ArgumentError; end

    Result = Struct.new(:invoice, :charge_result, keyword_init: true) do
      def success?
        charge_result.success?
      end
    end

    def initialize(gateway: Rails.application.config.x.payment_gateway)
      @gateway = gateway
    end

    def call(invoice)
      charge_result = nil

      invoice.with_lock do
        subscription = invoice.subscription
        subscription.reload
        ensure_chargeable!(invoice, subscription)

        charge_result = @gateway.charge(
          amount_cents: invoice.amount_cents,
          customer: invoice.customer,
          idempotency_key: "invoice-#{invoice.id}-attempt-#{invoice.payments.count + 1}"
        )

        invoice.payments.create!(
          amount_cents: invoice.amount_cents,
          status: charge_result.success? ? :succeeded : :failed,
          gateway_reference: charge_result.reference,
          failure_reason: charge_result.failure_reason
        )

        if charge_result.success?
          invoice.update!(status: :paid, paid_at: Time.current)
          subscription.update!(status: :active) if subscription.past_due?
        else
          subscription.update!(status: :past_due)
        end
      end

      Result.new(invoice: invoice.reload, charge_result: charge_result)
    end

    private

    def ensure_chargeable!(invoice, subscription)
      raise NotChargeableError, "invoice must be open to charge, was #{invoice.status}" unless invoice.open?
      raise NotChargeableError, "cannot charge an invoice for a canceled subscription" if subscription.canceled?
    end
  end
end
