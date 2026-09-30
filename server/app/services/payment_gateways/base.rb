module PaymentGateways
  # The interface every payment gateway must implement. PayDesk ships with
  # FakeGateway so the whole app runs with zero third-party accounts, but
  # anything that responds to #charge with a ChargeResult can be dropped in
  # (see PaymentGateways::StripeGateway.example in the README for the shape
  # a real integration would take).
  class Base
    # @param amount_cents [Integer]
    # @param customer [Customer]
    # @return [PaymentGateways::ChargeResult]
    def charge(amount_cents:, customer:)
      raise NotImplementedError, "#{self.class} must implement #charge"
    end
  end
end
