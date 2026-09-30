module Api
  class CustomersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer, only: [ :show, :update, :destroy ]

    def index
      render json: current_user.customers.order(created_at: :desc).map { |c| customer_json(c) }
    end

    def show
      render json: customer_json(@customer)
    end

    def create
      customer = current_user.customers.new(customer_params)
      customer.save!
      render json: customer_json(customer), status: :created
    end

    def update
      @customer.update!(customer_params)
      render json: customer_json(@customer)
    end

    def destroy
      @customer.destroy!
      head :no_content
    end

    private

    def set_customer
      @customer = current_user.customers.find(params[:id])
    end

    def customer_params
      params.permit(:name, :email)
    end

    def customer_json(customer)
      {
        id: customer.id,
        name: customer.name,
        email: customer.email,
        activeSubscriptionCount: customer.subscriptions.active.count,
        createdAt: customer.created_at
      }
    end
  end
end
