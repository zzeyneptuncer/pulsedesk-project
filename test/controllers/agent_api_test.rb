require "test_helper"

class AgentApiTest < ActionDispatch::IntegrationTest
  test "external agent can create ticket via API" do
    payload = {
      agent_id: "kubernetes_ingress_bot",
      title: "502 Bad Gateway Cluster Alarm",
      description: "Ingress controller cannot connect to auth-service.",
      error_code: "K8S_502_INGRESS",
      context: { namespace: "production", replicas: 0 }
    }

    assert_difference "Ticket.count", 1 do
      post "/api/v1/agent/tickets", params: payload, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "agent", Ticket.last.source_type
    assert json["ai_triage"]["diagnosis"].present?
  end

  test "HITL approval from UI succeeds" do
    ticket = Ticket.create_from_agent!(
      agent_id: "stripe_bot",
      title: "Stripe error",
      description: "Payment failed"
    )

    post approve_hitl_ticket_path(ticket)
    assert_response :see_other
    assert_equal "approved", ticket.reload.hitl_status
  end

  test "simulate agent incident from dashboard" do
    assert_difference "Ticket.count", 1 do
      post simulate_agent_incident_tickets_path
    end

    assert_response :see_other
    assert_equal "agent", Ticket.last.source_type
  end
end
