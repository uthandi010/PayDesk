class Plan < ApplicationRecord
  belongs_to :user
  has_many :subscriptions, dependent: :restrict_with_error

  enum :interval, { month: 0, year: 1 }

  validates :name, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }

  # How far a subscription on this plan advances per billing cycle.
  def period_length
    year? ? 1.year : 1.month
  end
end
