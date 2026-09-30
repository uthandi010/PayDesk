class User < ApplicationRecord
  has_secure_password

  has_many :customers, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :subscriptions, through: :customers
  has_many :invoices, through: :subscriptions

  before_validation { self.email = email.to_s.downcase.strip }

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
