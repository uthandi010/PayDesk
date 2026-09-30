class Invoice < ApplicationRecord
  belongs_to :subscription
  has_one :customer, through: :subscription
  has_one :user, through: :customer
  has_one :plan, through: :subscription
  has_many :payments, dependent: :destroy

  enum :status, { open: 0, paid: 1, void: 2 }

  before_validation :ensure_public_token, on: :create

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :public_token, presence: true, uniqueness: true

  def overdue?
    open? && due_date.present? && due_date.past?
  end

  private

  def ensure_public_token
    self.public_token ||= SecureRandom.urlsafe_base64(24)
  end
end
