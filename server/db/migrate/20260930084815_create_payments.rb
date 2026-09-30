class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.integer :status, null: false
      t.string :gateway_reference
      t.string :failure_reason

      t.timestamps
    end
  end
end
