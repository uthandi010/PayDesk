class Customer < ApplicationRecord
  belongs_to :user
  has_many :subscriptions, dependent: :destroy

  before_validation { self.email = email.to_s.downcase.strip }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
