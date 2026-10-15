module Api
  class SubscriptionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_subscription, only: [ :show, :cancel, :renew ]

    def index
      subs = current_user.subscriptions.includes(:customer, :plan).order(created_at: :desc)
      render json: subs.map { |s| subscription_json(s) }
    end

    def show
      render json: subscription_json(@subscription)
    end

    def create
      customer = current_user.customers.find(params[:customer_id])
      plan = current_user.plans.find(params[:plan_id])

      subscription = Billing::SubscriptionCreator.new.call(customer: customer, plan: plan)
      render json: subscription_json(subscription), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end

    def cancel
      # Void whatever is still open so a canceled subscription can't be
      # charged later through a retry or a public pay link.
      ActiveRecord::Base.transaction do
        @subscription.update!(status: :canceled)
        @subscription.invoices.open.update_all(status: :void, updated_at: Time.current)
      end
      render json: subscription_json(@subscription)
    end

    def renew
      subscription = Billing::SubscriptionRenewer.new.call(@subscription)
      render json: subscription_json(subscription)
    rescue Billing::SubscriptionRenewer::AlreadyCanceledError => e
      render json: { message: e.message }, status: :unprocessable_content
    end

    private

    def set_subscription
      @subscription = current_user.subscriptions.find(params[:id])
    end

    def subscription_json(sub)
      {
        id: sub.id,
        status: sub.status,
        currentPeriodStart: sub.current_period_start,
        currentPeriodEnd: sub.current_period_end,
        customer: { id: sub.customer.id, name: sub.customer.name, email: sub.customer.email },
        plan: { id: sub.plan.id, name: sub.plan.name, amountCents: sub.plan.amount_cents, interval: sub.plan.interval },
        latestInvoiceId: sub.invoices.order(created_at: :desc).first&.id
      }
    end
  end
end
