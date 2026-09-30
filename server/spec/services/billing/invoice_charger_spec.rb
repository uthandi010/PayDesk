require "rails_helper"

RSpec.describe Billing::InvoiceCharger do
  let(:user) { create(:user) }
  let(:charger) { described_class.new(gateway: PaymentGateways::FakeGateway.new) }

  describe "a successful charge" do
    it "marks the invoice paid, stamps paid_at, and records a succeeded payment" do
      customer = create(:customer, user: user, email: "regular@example.com")
      subscription = create(:subscription, user: user, customer: customer, status: :past_due)
      invoice = create(:invoice, subscription: subscription, amount_cents: 2900)

      result = charger.call(invoice)

      expect(result).to be_success
      expect(invoice.reload).to be_paid
      expect(invoice.paid_at).to be_present
      expect(invoice.payments.sole).to be_succeeded
      expect(invoice.payments.sole.amount_cents).to eq(2900)
    end

    it "brings a past_due subscription back to active" do
      customer = create(:customer, user: user, email: "regular@example.com")
      subscription = create(:subscription, user: user, customer: customer, status: :past_due)
      invoice = create(:invoice, subscription: subscription)

      charger.call(invoice)

      expect(subscription.reload).to be_active
    end
  end

  describe "a declined charge" do
    it "leaves the invoice open, records a failed payment, and marks the subscription past_due" do
      customer = create(:customer, user: user, email: "shopper@declined.test")
      subscription = create(:subscription, user: user, customer: customer, status: :active)
      invoice = create(:invoice, subscription: subscription, amount_cents: 2900)

      result = charger.call(invoice)

      expect(result).not_to be_success
      expect(invoice.reload).to be_open
      expect(invoice.paid_at).to be_nil
      expect(invoice.payments.sole).to be_failed
      expect(invoice.payments.sole.failure_reason).to eq("card_declined")
      expect(subscription.reload).to be_past_due
    end

    it "does not resurrect a canceled subscription" do
      customer = create(:customer, user: user, email: "shopper@declined.test")
      subscription = create(:subscription, user: user, customer: customer, status: :canceled)
      invoice = create(:invoice, subscription: subscription)

      charger.call(invoice)

      expect(subscription.reload).to be_canceled
    end
  end

  it "refuses to charge an invoice that isn't open" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer)
    invoice = create(:invoice, subscription: subscription, status: :paid)

    expect { charger.call(invoice) }.to raise_error(ArgumentError)
  end
end
