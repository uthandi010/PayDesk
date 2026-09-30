require "rails_helper"

RSpec.describe "Plans", type: :request do
  let(:user) { create(:user) }

  it "creates a plan" do
    post "/api/plans", params: { name: "Pro", amount_cents: 2900, interval: "month" }, headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["amountCents"]).to eq(2900)
  end

  it "rejects a non-positive price" do
    post "/api/plans", params: { name: "Free", amount_cents: 0, interval: "month" }, headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "refuses to delete a plan that has subscriptions" do
    plan = create(:plan, user: user)
    create(:subscription, user: user, plan: plan)

    delete "/api/plans/#{plan.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_content)
    expect(plan.reload).to be_present
  end

  it "deletes a plan with no subscriptions" do
    plan = create(:plan, user: user)

    delete "/api/plans/#{plan.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:no_content)
  end
end
