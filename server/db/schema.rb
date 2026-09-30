# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_30_084815) do
  create_table "customers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "amount_cents", null: false
    t.integer "status", default: 0, null: false
    t.datetime "due_date", null: false
    t.datetime "paid_at"
    t.string "public_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public_token"], name: "index_invoices_on_public_token", unique: true
    t.index ["subscription_id"], name: "index_invoices_on_subscription_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.integer "amount_cents", null: false
    t.integer "status", null: false
    t.string "gateway_reference"
    t.string "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "amount_cents", null: false
    t.integer "interval", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "plan_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "current_period_start", null: false
    t.datetime "current_period_end", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "customers", "users"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "payments", "invoices"
  add_foreign_key "plans", "users"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "subscriptions", "plans"
end
