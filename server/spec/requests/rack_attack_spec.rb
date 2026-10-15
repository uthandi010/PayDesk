require "rails_helper"

RSpec.describe "Request throttling", type: :request do
  # The test env's cache is a :null_store, which would make every throttle a
  # no-op; give Rack::Attack a real store just for these examples.
  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = original_store
  end

  describe "POST /api/auth/login" do
    it "throttles repeated attempts against one email, with a JSON 429" do
      5.times do
        post "/api/auth/login", params: { email: "victim@example.com", password: "wrong" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      post "/api/auth/login", params: { email: "Victim@Example.com ", password: "wrong" }, as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body["message"]).to match(/too many requests/i)
      expect(response.headers["retry-after"].to_i).to be_positive
    end

    it "throttles one IP spraying many different emails" do
      10.times do |i|
        post "/api/auth/login", params: { email: "user#{i}@example.com", password: "wrong" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      post "/api/auth/login", params: { email: "user99@example.com", password: "wrong" }, as: :json

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /api/auth/register" do
    it "throttles account creation per IP" do
      5.times do |i|
        post "/api/auth/register", params: { name: "U", email: "new#{i}@example.com", password: "password123" }, as: :json
        expect(response).to have_http_status(:created)
      end

      post "/api/auth/register", params: { name: "U", email: "new99@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /api/public/invoices/:token/pay" do
    it "throttles repeated pay attempts on one invoice link without touching other links" do
      subscription = create(:subscription)
      customer = subscription.customer
      customer.update!(email: "shopper@declined.test")
      invoice = create(:invoice, subscription: subscription)
      other_invoice = create(:invoice, subscription: subscription)

      5.times do
        post "/api/public/invoices/#{invoice.public_token}/pay"
        expect(response).to have_http_status(:ok)
      end

      post "/api/public/invoices/#{invoice.public_token}/pay"
      expect(response).to have_http_status(:too_many_requests)
      expect(invoice.payments.count).to eq(5)

      post "/api/public/invoices/#{other_invoice.public_token}/pay"
      expect(response).to have_http_status(:ok)
    end
  end

  it "doesn't throttle ordinary authenticated API traffic" do
    user = create(:user)

    15.times { get "/api/plans", headers: auth_headers(user) }

    expect(response).to have_http_status(:ok)
  end
end
