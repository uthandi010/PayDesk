module Api
  class PlansController < ApplicationController
    before_action :authenticate_user!
    before_action :set_plan, only: [ :show, :update, :destroy ]

    def index
      render json: current_user.plans.order(created_at: :desc).map { |p| plan_json(p) }
    end

    def show
      render json: plan_json(@plan)
    end

    def create
      plan = current_user.plans.new(plan_params)
      plan.save!
      render json: plan_json(plan), status: :created
    end

    def update
      @plan.update!(plan_params)
      render json: plan_json(@plan)
    end

    def destroy
      @plan.destroy!
      head :no_content
    rescue ActiveRecord::RecordNotDestroyed
      render json: { message: "Can't delete a plan that has subscriptions. Mark it inactive instead." },
             status: :unprocessable_content
    end

    private

    def set_plan
      @plan = current_user.plans.find(params[:id])
    end

    def plan_params
      params.permit(:name, :amount_cents, :interval, :active)
    end

    def plan_json(plan)
      {
        id: plan.id,
        name: plan.name,
        amountCents: plan.amount_cents,
        interval: plan.interval,
        active: plan.active,
        subscriptionCount: plan.subscriptions.count
      }
    end
  end
end
