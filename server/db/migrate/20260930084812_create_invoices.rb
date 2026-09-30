class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :subscription, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.integer :status, null: false, default: 0
      t.datetime :due_date, null: false
      t.datetime :paid_at
      t.string :public_token, null: false

      t.timestamps
    end
    add_index :invoices, :public_token, unique: true
  end
end
