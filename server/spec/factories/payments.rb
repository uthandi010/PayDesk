FactoryBot.define do
  factory :payment do
    invoice
    amount_cents { 2900 }
    status { :succeeded }
    gateway_reference { "fake_ch_test123" }
  end
end
