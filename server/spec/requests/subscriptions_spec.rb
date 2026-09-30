require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user, amount_cents: 2900) }

  it "creates a subscription and bills it immediately" do
    customer = create(:customer, user: user, email: "regular@example.com")

    post "/api/subscriptions", params: { customer_id: customer.id, plan_id: plan.id }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["status"]).to eq("active")
    expect(body["latestInvoiceId"]).to be_present
  end

  it "leaves a subscription past_due when the customer's first charge is declined" do
    customer = create(:customer, user: user, email: "shopper@declined.test")

    post "/api/subscriptions", params: { customer_id: customer.id, plan_id: plan.id }, headers: auth_headers(user)

    expect(response.parsed_body["status"]).to eq("past_due")
  end

  it "won't let you subscribe someone else's customer to your plan" do
    other_customer = create(:customer, user: create(:user))

    post "/api/subscriptions", params: { customer_id: other_customer.id, plan_id: plan.id }, headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end

  it "cancels a subscription" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer, plan: plan)

    patch "/api/subscriptions/#{subscription.id}/cancel", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("canceled")
  end

  it "renews a subscription into its next period" do
    customer = create(:customer, user: user, email: "regular@example.com")
    subscription = create(:subscription, user: user, customer: customer, plan: plan,
                           current_period_start: 1.month.ago, current_period_end: Time.current)

    post "/api/subscriptions/#{subscription.id}/renew", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(Subscription.find(subscription.id).invoices.count).to eq(1)
  end

  it "refuses to renew a canceled subscription" do
    customer = create(:customer, user: user)
    subscription = create(:subscription, user: user, customer: customer, plan: plan, status: :canceled)

    post "/api/subscriptions/#{subscription.id}/renew", headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
  end
end
