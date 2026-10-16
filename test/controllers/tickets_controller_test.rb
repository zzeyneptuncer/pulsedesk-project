require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 10, 16, 10)
    @ticket = Ticket.create!(title: "Kurumsal erişim", description: "SSO kontrolü", customer_name: "Ada", customer_email: "ada@example.com")
  end
  teardown { travel_back }

  test "complete workflow and SLA remain consistent across time" do
    assert_equal "new", @ticket.status
    %w[open pending solved].each do |status|
      patch transition_ticket_path(@ticket), params: { status: status }
      assert_response :see_other
      assert_equal status, @ticket.reload.status
    end
    deadline = @ticket.sla_due_at
    solved_at = @ticket.solved_at
    travel_to deadline + 1.day
    assert_not @ticket.reload.sla_breached?
    post reply_ticket_path(@ticket), params: { author_role: "customer", body: "Teşekkürler, sağ olun" }
    assert_equal "solved", @ticket.reload.status
    assert_equal 1, @ticket.reopen_prevented_count
    assert_equal deadline, @ticket.sla_due_at
    assert_equal solved_at, @ticket.solved_at
    assert @ticket.ticket_comments.last.prevented_reopen?
    post reply_ticket_path(@ticket), params: { author_role: "customer", body: "Teşekkürler ama hata devam ediyor" }
    assert_equal "open", @ticket.reload.status
    assert_equal Time.current + 8.hours, @ticket.sla_due_at
    assert_equal 1, @ticket.reopen_prevented_count
    assert_not @ticket.ticket_comments.last.prevented_reopen?
    patch transition_ticket_path(@ticket), params: { status: "new" }
    assert_equal "open", @ticket.reload.status
    travel_to @ticket.sla_due_at + 1.second
    assert @ticket.reload.sla_breached?
    get tickets_path(filter: "breached")
    assert_select ".ticket-title", text: @ticket.title
  end

  test "dashboard detail and new page render" do
    get root_path
    assert_response :success
    assert_select "h1", "Her talep kontrol altında."
    get ticket_path(@ticket)
    assert_response :success
    assert_select "form", minimum: 4
    get new_ticket_path
    assert_response :success
  end

  test "create then assign solve thank and reopen through HTTP" do
    assert_difference "Ticket.count", 1 do
      post tickets_path, params: { ticket: { title: "Yeni", description: "Detay", customer_name: "Ada", customer_email: "ada@example.com", priority: "high" } }
    end
    assert_response :redirect
    patch assign_ticket_path(@ticket), params: { assigned_agent: Ticket::AGENTS.first }
    assert_equal "open", @ticket.reload.status
    post reply_ticket_path(@ticket), params: { author_role: "agent", body: "Çözümü uyguladık" }
    patch transition_ticket_path(@ticket), params: { status: "solved" }
    post reply_ticket_path(@ticket), params: { author_role: "customer", body: "Teşekkürler!" }
    assert_equal "solved", @ticket.reload.status
    assert_equal 1, @ticket.reopen_prevented_count
    follow_redirect!
    assert_response :success
    assert_select ".guard-label", count: 1
    post reply_ticket_path(@ticket), params: { author_role: "customer", body: "Hâlâ çalışmıyor!" }
    assert_equal "open", @ticket.reload.status
  end

  test "filters and validation errors" do
    get tickets_path(filter: "solved")
    assert_response :success
    assert_select ".ticket-title", count: 0
    get tickets_path(filter: "breached")
    assert_response :success
    patch transition_ticket_path(@ticket), params: { status: "solved" }
    assert_equal "new", @ticket.reload.status
    post tickets_path, params: { ticket: { title: "" } }
    assert_response :unprocessable_entity
    post reply_ticket_path(@ticket), params: { author_role: "invalid", body: "Test" }
    assert_equal 0, @ticket.ticket_comments.count
  end

  test "simulation is blocked outside development" do
    post simulate_ticket_path(@ticket)
    assert_response :forbidden
  end
end
