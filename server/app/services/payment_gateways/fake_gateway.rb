module PaymentGateways
  # A deterministic stand-in for a real processor. No network call, no
  # account, no API key - so the whole app (including CI) runs end to end
  # with zero third-party dependencies. It fails on purpose for a couple of
  # documented "magic" customer email domains, the same trick real sandboxes
  # (Stripe test cards, PayPal sandbox accounts) use to let you exercise
  # failure paths on demand instead of hoping for flakiness.
  #
  # Swapping in a real processor later means writing one class that responds
  # to #charge the same way - nothing in Billing::InvoiceCharger, or any
  # controller, would need to change.
  class FakeGateway < Base
    DECLINED_DOMAIN = "declined.test"
    INSUFFICIENT_FUNDS_DOMAIN = "insufficientfunds.test"

    # idempotency_key is accepted to honour the Base interface; there is no
    # remote side here that could see a replayed request.
    def charge(amount_cents:, customer:, idempotency_key: nil)
      domain = customer.email.to_s.split("@").last

      case domain
      when DECLINED_DOMAIN
        ChargeResult.new(success: false, failure_reason: "card_declined")
      when INSUFFICIENT_FUNDS_DOMAIN
        ChargeResult.new(success: false, failure_reason: "insufficient_funds")
      else
        ChargeResult.new(success: true, reference: "fake_ch_#{SecureRandom.hex(10)}")
      end
    end
  end
end
