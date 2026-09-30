class JsonWebToken
  SECRET = Rails.application.secret_key_base

  def self.encode(payload, exp: 7.days.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
