require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds create five examples and preserve edits on repeated runs" do
    assert_difference "Ticket.count", 5 do
      Rails.application.load_seed
    end
    ticket = Ticket.find_by!(title: "SSO oturum açma hatası")
    ticket.assign_agent!(Ticket::AGENTS.first)
    snapshot = Ticket.order(:id).map(&:attributes)
    comments = TicketComment.order(:id).map(&:attributes)
    assert_no_difference ["Ticket.count", "TicketComment.count"] do
      Rails.application.load_seed
    end
    assert_equal snapshot, Ticket.order(:id).map(&:attributes)
    assert_equal comments, TicketComment.order(:id).map(&:attributes)
  end
end
