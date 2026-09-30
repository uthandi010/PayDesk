require "rails_helper"

RSpec.describe PaymentGateways::FakeGateway do
  subject(:gateway) { described_class.new }

  it "succeeds for an ordinary customer email" do
    customer = build(:customer, email: "regular@example.com")

    result = gateway.charge(amount_cents: 1000, customer: customer)

    expect(result).to be_success
    expect(result.reference).to be_present
    expect(result.failure_reason).to be_nil
  end

  it "declines a customer at the @declined.test domain" do
    customer = build(:customer, email: "shopper@declined.test")

    result = gateway.charge(amount_cents: 1000, customer: customer)

    expect(result).not_to be_success
    expect(result.failure_reason).to eq("card_declined")
    expect(result.reference).to be_nil
  end

  it "reports insufficient funds for a customer at the @insufficientfunds.test domain" do
    customer = build(:customer, email: "shopper@insufficientfunds.test")

    result = gateway.charge(amount_cents: 1000, customer: customer)

    expect(result).not_to be_success
    expect(result.failure_reason).to eq("insufficient_funds")
  end

  it "gives each successful charge a unique reference" do
    customer = build(:customer, email: "regular@example.com")

    refs = Array.new(5) { gateway.charge(amount_cents: 500, customer: customer).reference }

    expect(refs.uniq.size).to eq(5)
  end
end
