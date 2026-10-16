class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :assigned_agent
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "new"
      t.datetime :sla_due_at, null: false
      t.datetime :first_responded_at
      t.datetime :solved_at
      t.integer :reopen_prevented_count, null: false, default: 0
      t.timestamps
    end
    add_index :tickets, [:status, :sla_due_at]
    create_table :ticket_comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.string :author_name, null: false
      t.string :author_role, null: false
      t.text :body, null: false
      t.boolean :prevented_reopen, null: false, default: false
      t.timestamps
    end
  end
end
