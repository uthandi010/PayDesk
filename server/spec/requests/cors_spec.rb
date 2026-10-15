require "rails_helper"

# Origins come from ENV["CORS_ORIGINS"] when the app boots; with it unset (as
# in the test env) they default to the Vite dev server.
RSpec.describe "CORS", type: :request do
  it "allows the default local dev origin" do
    get "/api/plans", headers: { "Origin" => "http://localhost:5173" }

    expect(response.headers["access-control-allow-origin"]).to eq("http://localhost:5173")
  end

  it "doesn't allow an unlisted origin" do
    get "/api/plans", headers: { "Origin" => "https://evil.example" }

    expect(response.headers["access-control-allow-origin"]).to be_nil
  end
end
