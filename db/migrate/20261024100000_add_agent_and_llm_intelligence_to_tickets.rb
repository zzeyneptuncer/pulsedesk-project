class AddAgentAndLlmIntelligenceToTickets < ActiveRecord::Migration[8.1]
  def change
    change_table :tickets do |t|
      t.string :source_type, null: false, default: "human"
      t.string :source_agent_id
      t.boolean :sarcasm_detected, null: false, default: false
      t.string :ai_intent
      t.string :ai_sentiment
      t.text :ai_triage_diagnosis
      t.text :ai_proposed_action
      t.string :hitl_status, null: false, default: "none"
    end

    change_table :ticket_comments do |t|
      t.boolean :sarcasm_detected, null: false, default: false
      t.string :ai_intent
      t.float :ai_confidence
    end
  end
end
