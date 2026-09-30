# The single place the app decides which payment gateway implementation to
# use. Swapping PayDesk onto a real processor later means writing a class
# under app/services/payment_gateways that implements #charge the way
# PaymentGateways::Base documents, and changing this one line - nothing else
# in the app references a gateway class by name.
#
# Wrapped in to_prepare (rather than assigned directly) because autoloading
# isn't ready yet while config/initializers run - to_prepare fires once
# autoloading is set up, and again on every reload in development.
Rails.application.config.to_prepare do
  Rails.application.config.x.payment_gateway = PaymentGateways::FakeGateway.new
end
