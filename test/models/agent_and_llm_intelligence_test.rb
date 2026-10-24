require "test_helper"

class AgentAndLlmIntelligenceTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 24, 10, 0, 0)
    @ticket = Ticket.create!(
      title: "Sistem arayüzü",
      description: "Genel inceleme",
      customer_name: "Zeynep Tuncer",
      customer_email: "zeynep@example.com",
      priority: "medium"
    )
  end

  teardown { travel_back }

  test "LLM detects sarcasm and escalates SLA to urgent" do
    @ticket.transition_to!("open")
    @ticket.transition_to!("solved")
    assert_equal "solved", @ticket.status
    assert_equal "medium", @ticket.priority

    sarcastic_body = "Harika sistem yapmışsınız, 3 gündür çöktü çok teşekkürler!"
    reply = @ticket.add_customer_reply!(sarcastic_body, customer_name: "Zeynep Tuncer")

    @ticket.reload
    assert_not reply.prevented_reopen?
    assert reply.sarcasm_detected?
    assert @ticket.sarcasm_detected?
    assert_equal "open", @ticket.status
    assert_equal "urgent", @ticket.priority
    assert_equal Time.current + 1.hour, @ticket.sla_due_at
  end

  test "LLM preserves solution for genuine gratitude" do
    @ticket.transition_to!("open")
    @ticket.transition_to!("solved")

    genuine_body = "Teşekkürler, sorun tamamen çözüldü elinize sağlık!"
    reply = @ticket.add_customer_reply!(genuine_body, customer_name: "Zeynep Tuncer")

    @ticket.reload
    assert reply.prevented_reopen?
    assert_not reply.sarcasm_detected?
    assert_equal "solved", @ticket.status
    assert_equal 1, @ticket.reopen_prevented_count
  end

  test "Agent-First creation with automatic triage and HITL requirement" do
    ticket = Ticket.create_from_agent!(
      agent_id: "stripe_billing_worker",
      title: "Stripe Webhook Gateway Timeout",
      description: "504 Gateway Timeout while processing payment charge ID ch_894172.",
      error_code: "PAYMENT_TIMEOUT_504",
      context: { service: "checkout", retry_count: 3 }
    )

    assert_equal "agent", ticket.source_type
    assert_equal "stripe_billing_worker", ticket.source_agent_id
    assert_equal "urgent", ticket.priority
    assert_equal "pending_human_approval", ticket.hitl_status
    assert_includes ticket.ai_triage_diagnosis, "Ödeme ağ geçidi"

    # Human-in-the-Loop onayı
    ticket.approve_hitl_action!(approved_by: "Deniz Yılmaz")
    ticket.reload

    assert_equal "approved", ticket.hitl_status
    assert_equal "open", ticket.status
    assert_includes ticket.ticket_comments.last.body, "İnsan Mühendis Onayı Verildi (HITL)"
  end

  test "Agent-First HITL rejection transitions cleanly" do
    ticket = Ticket.create_from_agent!(
      agent_id: "database_cluster_agent",
      title: "Veritabanı Kilitlenme Alarmı",
      description: "Deadlock detected on accounts table.",
      error_code: "DB_DEADLOCK_40"
    )

    assert_equal "pending_human_approval", ticket.hitl_status

    ticket.reject_hitl_action!(rejected_by: "Mert Kaya", reason: "Migration rollback gerekiyor.")
    ticket.reload

    assert_equal "rejected", ticket.hitl_status
    assert_equal "open", ticket.status
    assert_includes ticket.ticket_comments.last.body, "AI Aksiyonu Reddedildi (HITL)"
  end
end
