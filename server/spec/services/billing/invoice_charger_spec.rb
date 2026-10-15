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
  end

  it "refuses to charge an invoice that isn't open" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer)
    invoice = create(:invoice, subscription: subscription, status: :paid)

    expect { charger.call(invoice) }.to raise_error(ArgumentError)
  end

  describe "guarding against double charges and uncollectable invoices" do
    let(:gateway) { instance_spy(PaymentGateways::FakeGateway) }
    let(:charger) { described_class.new(gateway: gateway) }
    let(:subscription) { create(:subscription, user: user) }

    it "re-checks the invoice under a lock, so a stale copy of an already-paid invoice is not charged again" do
      invoice = create(:invoice, subscription: subscription, status: :open)
      stale_copy = Invoice.find(invoice.id)
      # Another request pays the invoice after we loaded our copy.
      invoice.update!(status: :paid, paid_at: Time.current)

      expect { charger.call(stale_copy) }.to raise_error(Billing::InvoiceCharger::NotChargeableError, /was paid/)
      expect(gateway).not_to have_received(:charge)
      expect(invoice.payments).to be_empty
    end

    it "refuses a void invoice without calling the gateway" do
      invoice = create(:invoice, subscription: subscription, status: :void)

      expect { charger.call(invoice) }.to raise_error(Billing::InvoiceCharger::NotChargeableError, /was void/)
      expect(gateway).not_to have_received(:charge)
    end

    it "refuses an open invoice whose subscription is canceled, without calling the gateway" do
      subscription.update!(status: :canceled)
      invoice = create(:invoice, subscription: subscription, status: :open)

      expect { charger.call(invoice) }.to raise_error(Billing::InvoiceCharger::NotChargeableError, /canceled/)
      expect(gateway).not_to have_received(:charge)
      expect(invoice.reload).to be_open
      expect(subscription.reload).to be_canceled
    end

    it "sends the gateway an idempotency key that is stable per invoice attempt" do
      allow(gateway).to receive(:charge)
        .and_return(PaymentGateways::ChargeResult.new(success: false, failure_reason: "card_declined"))
      invoice = create(:invoice, subscription: subscription, status: :open)

      2.times { charger.call(invoice) }

      expect(gateway).to have_received(:charge)
        .with(hash_including(idempotency_key: "invoice-#{invoice.id}-attempt-1")).ordered
      expect(gateway).to have_received(:charge)
        .with(hash_including(idempotency_key: "invoice-#{invoice.id}-attempt-2")).ordered
    end
  end
end
