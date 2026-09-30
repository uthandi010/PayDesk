class Payment < ApplicationRecord
  belongs_to :invoice

  enum :status, { succeeded: 0, failed: 1 }

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
end
