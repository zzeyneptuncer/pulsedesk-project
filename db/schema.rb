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

ActiveRecord::Schema[8.1].define(version: 2026_10_24_100000) do
  create_table "ticket_comments", force: :cascade do |t|
    t.float "ai_confidence"
    t.string "ai_intent"
    t.string "author_name", null: false
    t.string "author_role", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "prevented_reopen", default: false, null: false
    t.boolean "sarcasm_detected", default: false, null: false
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_ticket_comments_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "ai_intent"
    t.text "ai_proposed_action"
    t.string "ai_sentiment"
    t.text "ai_triage_diagnosis"
    t.string "assigned_agent"
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.text "description", null: false
    t.datetime "first_responded_at"
    t.string "hitl_status", default: "none", null: false
    t.string "priority", default: "medium", null: false
    t.integer "reopen_prevented_count", default: 0, null: false
    t.boolean "sarcasm_detected", default: false, null: false
    t.datetime "sla_due_at", null: false
    t.datetime "solved_at"
    t.string "source_agent_id"
    t.string "source_type", default: "human", null: false
    t.string "status", default: "new", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "sla_due_at"], name: "index_tickets_on_status_and_sla_due_at"
  end

  add_foreign_key "ticket_comments", "tickets"
end
