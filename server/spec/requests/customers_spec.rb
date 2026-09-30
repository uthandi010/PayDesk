require "rails_helper"

RSpec.describe "Customers", type: :request do
  let(:user) { create(:user) }

  it "requires authentication" do
    get "/api/customers"
    expect(response).to have_http_status(:unauthorized)
  end

  it "creates and lists a customer scoped to the current user" do
    post "/api/customers", params: { name: "Alex", email: "alex@example.com" }, headers: auth_headers(user)
    expect(response).to have_http_status(:created)

    get "/api/customers", headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.size).to eq(1)
    expect(response.parsed_body.first["email"]).to eq("alex@example.com")
  end

  it "never returns another account's customers" do
    other_user = create(:user)
    create(:customer, user: other_user)

    get "/api/customers", headers: auth_headers(user)

    expect(response.parsed_body).to eq([])
  end

  it "404s trying to fetch another account's customer directly" do
    other_customer = create(:customer, user: create(:user))

    get "/api/customers/#{other_customer.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:not_found)
  end

  it "rejects an invalid email" do
    post "/api/customers", params: { name: "Alex", email: "not-an-email" }, headers: auth_headers(user)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
