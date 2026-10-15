# Throttles the endpoints that are worth abusing: login/register (credential
# stuffing, account spam) and the unauthenticated public pay link (hammering
# a card through the gateway). Counters live in Rails.cache - solid_cache in
# production, memory in development. The test environment uses :null_store,
# so throttles are inert there unless a spec gives Rack::Attack a real store.
#
# Set RACK_ATTACK_ENABLED=false to switch throttling off.
Rack::Attack.enabled = ENV.fetch("RACK_ATTACK_ENABLED", "true") != "false"

module PayDeskThrottles
  LOGIN_PATH = "/api/auth/login".freeze
  REGISTER_PATH = "/api/auth/register".freeze
  PUBLIC_PAY_PATH = %r{\A/api/public/invoices/(?<token>[^/]+)/pay\z}

  def self.login_email(req)
    # The client posts JSON, which Rack::Request#params doesn't parse.
    email = ActionDispatch::Request.new(req.env).params["email"]
    email.to_s.strip.downcase.presence
  rescue ActionDispatch::Http::Parameters::ParseError
    nil
  end
end

Rack::Attack.throttle("auth/login/ip", limit: 10, period: 1.minute) do |req|
  req.ip if req.post? && req.path == PayDeskThrottles::LOGIN_PATH
end

Rack::Attack.throttle("auth/login/email", limit: 5, period: 1.minute) do |req|
  PayDeskThrottles.login_email(req) if req.post? && req.path == PayDeskThrottles::LOGIN_PATH
end

Rack::Attack.throttle("auth/register/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.post? && req.path == PayDeskThrottles::REGISTER_PATH
end

Rack::Attack.throttle("public/pay/ip", limit: 10, period: 1.minute) do |req|
  req.ip if req.post? && PayDeskThrottles::PUBLIC_PAY_PATH.match?(req.path)
end

Rack::Attack.throttle("public/pay/token", limit: 5, period: 1.minute) do |req|
  req.post? && PayDeskThrottles::PUBLIC_PAY_PATH.match(req.path)&.[](:token)
end

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"]
  retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])

  [
    429,
    { "content-type" => "application/json", "retry-after" => retry_after.to_s },
    [ { message: "Too many requests. Please try again later." }.to_json ]
  ]
end
