require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  it "returns revenue summary numbers" do
    plan = create(:plan, user: user, amount_cents: 2000)
    customer = create(:customer, user: user, email: "regular@example.com")
    create(:subscription, user: user, customer: customer, plan: plan, status: :active)

    get "/api/dashboard/summary", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["mrrCents"]).to eq(2000)
    expect(body["activeSubscriptions"]).to eq(1)
    expect(body["revenueByMonth"]).to be_an(Array)
  end

  it "requires authentication" do
    get "/api/dashboard/summary"
    expect(response).to have_http_status(:unauthorized)
  end
end
