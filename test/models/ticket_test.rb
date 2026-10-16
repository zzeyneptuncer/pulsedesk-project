require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 16, 10)
    @ticket = Ticket.create!(title: "SSO sorunu", description: "Oturum açılamıyor", customer_name: "Ada", customer_email: "ada@example.com")
  end
  teardown { travel_back }

  test "all priority deadlines are calculated from creation" do
    { low: 24, medium: 8, high: 4, urgent: 1 }.each do |priority, hours|
      ticket = Ticket.create!(title: "Test", description: "Açıklama", customer_name: "Ada", customer_email: "ada@example.com", priority: priority)
      assert_equal Time.current + hours.hours, ticket.sla_due_at
    end
  end

  test "SLA boundary and negative remaining time" do
    travel_to @ticket.sla_due_at do
      assert_not @ticket.sla_breached?
      assert_equal 0, @ticket.sla_remaining_seconds
    end
    travel_to @ticket.sla_due_at + 1.second do
      assert @ticket.sla_breached?
      assert_equal(-1, @ticket.sla_remaining_seconds)
      assert_includes Ticket.breached, @ticket
    end
  end

  test "every allowed and forbidden status transition" do
    Ticket::STATUSES.product(Ticket::STATUSES).each do |from, to|
      @ticket.update_columns(status: from, assigned_agent: nil)
      @ticket.reload
      if from == to || Ticket::TRANSITIONS.fetch(from).include?(to)
        @ticket.transition_to!(to)
        assert_equal to, @ticket.reload.status
      else
        assert_raises(ActiveRecord::RecordInvalid) { @ticket.transition_to!(to) }
        assert_equal from, @ticket.reload.status
      end
    end
  end

  test "direct invalid updates are rejected" do
    assert_not @ticket.update(status: "solved")
    assert_equal "new", @ticket.reload.status
    @ticket.assign_agent!(Ticket::AGENTS.first)
    assert_not @ticket.update(status: "new")
    assert_equal "open", @ticket.reload.status
  end

  test "assignment and agent first response open new tickets" do
    @ticket.assign_agent!(Ticket::AGENTS.first)
    assert_equal "open", @ticket.status
    assert_nil @ticket.first_responded_at
    @ticket.add_agent_reply!("İnceliyoruz", author_name: "Deniz")
    first_response = @ticket.first_responded_at
    travel 1.hour
    @ticket.add_agent_reply!("İnceleme sürüyor", author_name: "Deniz")
    assert_equal first_response, @ticket.first_responded_at
  end

  test "first reply without assignment opens a ticket" do
    @ticket.add_agent_reply!("Merhaba", author_name: "Deniz")
    assert_equal "open", @ticket.status
    assert_equal Time.current, @ticket.first_responded_at
  end

  test "thanks preserve solution timestamps and increment protected count" do
    solve_ticket
    original = @ticket.attributes.slice("sla_due_at", "solved_at", "first_responded_at")
    ["Teşekkürler, sağ olun", "Sağ olun", "Thanks", "Thank you!", "Teşekkür ederim, çözüldü", "Harika!", "Süper"].each do |body|
      reply = @ticket.add_customer_reply!(body, customer_name: "Ada")
      assert reply.prevented_reopen?
      assert_equal "solved", @ticket.reload.status
      assert_equal original, @ticket.attributes.slice(*original.keys)
    end
    assert_equal 7, @ticket.reopen_prevented_count
  end

  test "actual issues reopen with a fresh deadline" do
    ["Teşekkürler ama hata devam ediyor", "Hâlâ Çalışmıyor!", "Thanks, can you help?", "Teşekkürler, bağlantı koptu", "Teşekkürler fakat çözülmedi"].each do |body|
      solve_ticket
      travel 2.hours
      reply = @ticket.add_customer_reply!(body, customer_name: "Ada")
      assert_not reply.prevented_reopen?
      assert_equal "open", @ticket.status
      assert_equal Time.current + 8.hours, @ticket.sla_due_at
      assert_nil @ticket.solved_at
      assert_nil @ticket.first_responded_at
    end
  end

  test "pending customer reply opens without restarting SLA" do
    @ticket.transition_to!("open")
    @ticket.transition_to!("pending")
    deadline = @ticket.sla_due_at
    @ticket.add_customer_reply!("İstenen bilgiler ekte", customer_name: "Ada")
    assert_equal "open", @ticket.status
    assert_equal deadline, @ticket.sla_due_at
  end

  test "invalid comment rolls back all changes" do
    solve_ticket
    assert_no_difference ["TicketComment.count", "Ticket.sum(:reopen_prevented_count)"] do
      assert_raises(ActiveRecord::RecordInvalid) { @ticket.add_customer_reply!("", customer_name: "Ada") }
    end
    assert_equal "solved", @ticket.reload.status
  end

  test "solved SLA stays frozen and late solutions remain breached" do
    solve_ticket
    remaining = @ticket.sla_remaining_seconds
    travel 2.days
    assert_not @ticket.sla_breached?
    assert_equal remaining, @ticket.sla_remaining_seconds
    @ticket.transition_to!("open")
    travel 9.hours
    @ticket.transition_to!("solved")
    assert @ticket.sla_breached?
    assert_includes Ticket.breached, @ticket
  end

  test "five hour simulation shifts both timestamps" do
    due, created = @ticket.sla_due_at, @ticket.created_at
    @ticket.simulate_five_hours!
    assert_equal due - 5.hours, @ticket.sla_due_at
    assert_equal created - 5.hours, @ticket.created_at
  end

  private

  def solve_ticket
    @ticket.transition_to!("open") if @ticket.status == "new"
    @ticket.transition_to!("solved") unless @ticket.status == "solved"
  end
end
