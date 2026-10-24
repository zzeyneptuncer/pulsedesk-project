module Api
  module V1
    module Agent
      class TicketsController < ActionController::API
        def create
          agent_id = params[:agent_id].presence || "external_monitoring_agent"
          title = params[:title].presence || "Otonom Sistem Uyarısı"
          description = params[:description].presence || "Otomatik incident raporu."
          error_code = params[:error_code]
          context = params[:context] || {}

          ticket = Ticket.create_from_agent!(
            agent_id: agent_id,
            title: title,
            description: description,
            error_code: error_code,
            context: context
          )

          render json: {
            success: true,
            ticket_id: ticket.id,
            ticket_url: "/tickets/#{ticket.id}",
            title: ticket.title,
            priority: ticket.priority,
            status: ticket.status,
            hitl_status: ticket.hitl_status,
            ai_triage: {
              diagnosis: ticket.ai_triage_diagnosis,
              proposed_action: ticket.ai_proposed_action,
              requires_human_approval: ticket.hitl_status == "pending_human_approval"
            }
          }, status: :created
        rescue => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
