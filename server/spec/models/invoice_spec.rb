require "rails_helper"

RSpec.describe Invoice do
  it "generates a unique public_token on create" do
    invoice_a = create(:invoice)
    invoice_b = create(:invoice)

    expect(invoice_a.public_token).to be_present
    expect(invoice_a.public_token).not_to eq(invoice_b.public_token)
  end

  describe "#overdue?" do
    it "is true for an open invoice past its due date" do
      invoice = create(:invoice, status: :open, due_date: 1.day.ago)
      expect(invoice).to be_overdue
    end

    it "is false for a paid invoice even if its due date has passed" do
      invoice = create(:invoice, status: :paid, due_date: 1.day.ago, paid_at: Time.current)
      expect(invoice).not_to be_overdue
    end

    it "is false for an open invoice whose due date hasn't arrived yet" do
      invoice = create(:invoice, status: :open, due_date: 1.day.from_now)
      expect(invoice).not_to be_overdue
    end
  end
end
