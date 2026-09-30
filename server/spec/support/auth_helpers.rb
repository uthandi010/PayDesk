module AuthHelpers
  def auth_headers(user)
    { "Authorization" => "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
