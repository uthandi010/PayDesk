module PaymentGateways
  # The result of a single charge attempt, in a shape that is the same no
  # matter which gateway produced it. Billing::InvoiceCharger only ever talks
  # to this, never to a specific gateway's response format.
  ChargeResult = Struct.new(:success, :reference, :failure_reason, keyword_init: true) do
    def success?
      !!success
    end
  end
end
