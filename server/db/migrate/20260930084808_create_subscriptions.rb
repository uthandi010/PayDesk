class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :current_period_start, null: false
      t.datetime :current_period_end, null: false

      t.timestamps
    end
  end
end
