class ApplicationController < ActionController::API
  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end

  rescue_from AuthenticationError, with: :render_unauthorized
  rescue_from AuthorizationError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

  attr_reader :current_user

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = token && JsonWebToken.decode(token)
    raise AuthenticationError if payload.nil?

    @current_user = User.find_by(id: payload[:user_id])
    raise AuthenticationError if @current_user.nil?
  end

  def render_unauthorized
    render json: { message: "You must be logged in to do that." }, status: :unauthorized
  end

  def render_forbidden
    render json: { message: "You don't have access to do that." }, status: :forbidden
  end

  def render_not_found
    render json: { message: "Not found." }, status: :not_found
  end

  def render_unprocessable(exception)
    render json: { message: exception.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end
end
