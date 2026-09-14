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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_145325) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "asset_uid"
    t.datetime "created_at", null: false
    t.integer "critical_vulnerability_count"
    t.boolean "has_malware"
    t.string "host_type"
    t.string "host_type_source"
    t.string "hostname"
    t.string "ip_address"
    t.integer "malware_count"
    t.integer "moderate_vulnerability_count"
    t.string "operating_system"
    t.string "os_architecture"
    t.decimal "os_certainty"
    t.string "os_family"
    t.string "os_product"
    t.string "os_vendor"
    t.string "os_version"
    t.boolean "pci_compliant"
    t.decimal "raw_risk_score"
    t.decimal "risk_score"
    t.integer "severe_vulnerability_count"
    t.datetime "updated_at", null: false
    t.index ["asset_uid"], name: "index_assets_on_asset_uid", unique: true
  end

  create_table "csv_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "filename"
    t.integer "rows_count"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_csv_imports_on_user_id"
  end

  create_table "findings", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.bigint "csv_import_id", null: false
    t.datetime "date_added"
    t.datetime "date_modified"
    t.datetime "discovery_date"
    t.datetime "due_date"
    t.datetime "first_found"
    t.boolean "has_malware"
    t.boolean "in_grace_period"
    t.integer "instance_count"
    t.boolean "past_due"
    t.datetime "reintroduced"
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.bigint "vulnerability_id", null: false
    t.index ["asset_id", "vulnerability_id"], name: "index_findings_on_asset_id_and_vulnerability_id", unique: true
    t.index ["asset_id"], name: "index_findings_on_asset_id"
    t.index ["csv_import_id"], name: "index_findings_on_csv_import_id"
    t.index ["status"], name: "index_findings_on_status"
    t.index ["vulnerability_id"], name: "index_findings_on_vulnerability_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "vulnerabilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "cvss_access_complexity"
    t.string "cvss_access_vector"
    t.string "cvss_authentication"
    t.string "cvss_availability_impact"
    t.string "cvss_confidentiality_impact"
    t.string "cvss_integrity_impact"
    t.decimal "cvss_score"
    t.datetime "date_published"
    t.integer "exploit_count"
    t.boolean "has_exploits"
    t.integer "pci_severity"
    t.string "severity"
    t.integer "severity_rank"
    t.integer "severity_score"
    t.integer "skill_level_rank"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "vulnerability_uid"
    t.index ["vulnerability_uid"], name: "index_vulnerabilities_on_vulnerability_uid", unique: true
  end

  add_foreign_key "csv_imports", "users"
  add_foreign_key "findings", "assets"
  add_foreign_key "findings", "csv_imports"
  add_foreign_key "findings", "vulnerabilities"
  add_foreign_key "sessions", "users"
end
