require "rails_helper"

RSpec.describe "Invoices", type: :request do
  let(:user) { create(:user) }

  it "lists invoices scoped to the current user" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer)
    create(:invoice, subscription: subscription)

    other_subscription = create(:subscription)
    create(:invoice, subscription: other_subscription)

    get "/api/invoices", headers: auth_headers(user)

    expect(response.parsed_body.size).to eq(1)
  end

  it "retries a declined invoice and succeeds once the customer's email no longer declines" do
    customer = create(:customer, user: user, email: "shopper@declined.test")
    subscription = create(:subscription, user: user, customer: customer)
    invoice = create(:invoice, subscription: subscription, status: :open)

    Billing::InvoiceCharger.new.call(invoice) # first attempt fails, invoice stays open
    customer.update!(email: "regular@example.com")

    post "/api/invoices/#{invoice.id}/retry", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("paid")
  end

  it "refuses to retry an invoice that's already paid" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer)
    invoice = create(:invoice, subscription: subscription, status: :paid, paid_at: Time.current)

    post "/api/invoices/#{invoice.id}/retry", headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "downloads a PDF for an invoice" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer)
    invoice = create(:invoice, subscription: subscription)

    get "/api/invoices/#{invoice.id}/pdf", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eq("application/pdf")
    expect(response.body.byteslice(0, 4)).to eq("%PDF")
  end

  describe "the public invoice link" do
    it "can be viewed without authentication" do
      customer = create(:customer, user: user, name: "Alex Customer")
      subscription = create(:subscription, user: user, customer: customer)
      invoice = create(:invoice, subscription: subscription)

      get "/api/public/invoices/#{invoice.public_token}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["customer"]["name"]).to eq("Alex Customer")
    end

    it "404s for a bogus token" do
      get "/api/public/invoices/not-a-real-token"
      expect(response).to have_http_status(:not_found)
    end

    it "lets the customer pay their own invoice" do
      customer = create(:customer, user: user, email: "regular@example.com")
      subscription = create(:subscription, user: user, customer: customer)
      invoice = create(:invoice, subscription: subscription, status: :open)

      post "/api/public/invoices/#{invoice.public_token}/pay"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("paid")
    end
  end
end
