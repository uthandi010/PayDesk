class Subscription < ApplicationRecord
  belongs_to :customer
  belongs_to :plan
  has_one :user, through: :customer
  has_many :invoices, dependent: :destroy

  enum :status, { active: 0, past_due: 1, canceled: 2 }

  validate :plan_and_customer_belong_to_the_same_user

  private

  def plan_and_customer_belong_to_the_same_user
    return if customer.nil? || plan.nil?

    if customer.user_id != plan.user_id
      errors.add(:plan, "must belong to the same account as the customer")
    end
  end
end
