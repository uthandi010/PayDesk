module Api
  class AuthController < ApplicationController
    def register
      user = User.new(name: params[:name], email: params[:email], password: params[:password])

      if user.save
        render json: auth_response(user), status: :created
      else
        render json: { message: user.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    def login
      user = User.find_by(email: params[:email].to_s.strip.downcase)

      if user&.authenticate(params[:password])
        render json: auth_response(user)
      else
        render json: { message: "Invalid email or password." }, status: :unauthorized
      end
    end

    private

    def auth_response(user)
      { token: JsonWebToken.encode({ user_id: user.id }), userId: user.id, name: user.name, email: user.email }
    end
  end
end
