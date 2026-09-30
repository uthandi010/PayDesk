require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "POST /api/auth/register" do
    it "creates a user and returns a token" do
      post "/api/auth/register", params: { name: "Jamie", email: "jamie@example.com", password: "password123" }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["token"]).to be_present
      expect(body["email"]).to eq("jamie@example.com")
    end

    it "rejects a duplicate email" do
      create(:user, email: "jamie@example.com")

      post "/api/auth/register", params: { name: "Jamie", email: "jamie@example.com", password: "password123" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/auth/login" do
    it "logs in with correct credentials" do
      create(:user, email: "jamie@example.com", password: "password123")

      post "/api/auth/login", params: { email: "jamie@example.com", password: "password123" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["token"]).to be_present
    end

    it "rejects a wrong password" do
      create(:user, email: "jamie@example.com", password: "password123")

      post "/api/auth/login", params: { email: "jamie@example.com", password: "wrongpass" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
