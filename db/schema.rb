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

ActiveRecord::Schema[8.1].define(version: 2026_09_09_010000) do
  create_table "custom_domains", force: :cascade do |t|
    t.boolean "apx_hit"
    t.datetime "created_at", null: false
    t.string "dns_pointed_at"
    t.boolean "has_ssl"
    t.string "hostname", null: false
    t.boolean "is_resolving"
    t.string "lifecycle", default: "unconfirmed", null: false
    t.integer "provider_id"
    t.string "status", default: "pending", null: false
    t.text "status_message"
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.text "user_message"
    t.index ["hostname"], name: "index_custom_domains_on_hostname", unique: true
    t.index ["provider_id"], name: "index_custom_domains_on_provider_id", unique: true
    t.index ["tenant_id"], name: "index_custom_domains_on_tenant_id"
    t.check_constraint "lifecycle IN ('provisioning', 'active', 'unconfirmed', 'removal_pending', 'fixture')", name: "custom_domains_lifecycle"
  end

  create_table "pages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_pages_on_domain", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "headline", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tenants_on_slug", unique: true
  end

  add_foreign_key "custom_domains", "tenants"
end
