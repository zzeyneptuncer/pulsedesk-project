class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show transition assign reply simulate approve_hitl reject_hitl]
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_action

  def index
    @total = Ticket.count
    @breached = Ticket.breached.count
    @solved = Ticket.where(status: "solved").count
    @protected = Ticket.sum(:reopen_prevented_count)
    @agent_count = Ticket.agent_sourced.count
    @sarcasm_count = Ticket.sarcasm_flagged.count
    @pending_hitl_count = Ticket.pending_hitl.count
    @filter = params[:filter].to_s
    @tickets = Ticket.order(updated_at: :desc)
    @tickets = @tickets.where(status: @filter) if Ticket::STATUSES.include?(@filter)
    @tickets = @tickets.breached if @filter == "breached"
    @tickets = @tickets.agent_sourced if @filter == "agent"
    @tickets = @tickets.sarcasm_flagged if @filter == "sarcasm"
    @tickets = @tickets.pending_hitl if @filter == "hitl"
  end

  def show
    @comments = @ticket.ticket_comments.order(:created_at, :id)
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(params.require(:ticket).permit(:title, :description, :customer_name, :customer_email, :priority))
    if @ticket.save
      redirect_to @ticket, notice: "Talep oluşturuldu."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def transition
    @ticket.transition_to!(params[:status])
    redirect_to @ticket, notice: "Durum güncellendi.", status: :see_other
  end

  def assign
    @ticket.assign_agent!(params[:assigned_agent])
    redirect_to @ticket, notice: "Temsilci atandı.", status: :see_other
  end

  def reply
    if params[:author_role] == "agent"
      @ticket.add_agent_reply!(params[:body], author_name: @ticket.assigned_agent.presence || Ticket::AGENTS.first)
      message = "Temsilci yanıtı kaydedildi."
    elsif params[:author_role] == "customer"
      comment = @ticket.add_customer_reply!(params[:body], customer_name: @ticket.customer_name)
      if comment.sarcasm_detected?
        message = "⚠️ LLM Sarkazm Uyarısı: Müşterinin alaycı öfkesi yakalandı, talep acil (urgent) seviyede yeniden açıldı!"
      elsif comment.prevented_reopen?
        message = "Teşekkür filtresi çözümü korudu. SLA değişmedi."
      else
        message = "Müşteri yanıtı kaydedildi."
      end
    else
      return redirect_to @ticket, alert: "Geçersiz yanıt rolü.", status: :see_other
    end
    redirect_to @ticket, notice: message, status: :see_other
  end

  def approve_hitl
    @ticket.approve_hitl_action!(approved_by: @ticket.assigned_agent.presence || Ticket::AGENTS.first)
    redirect_to @ticket, notice: "✓ İnsan Mühendis Onayı Verildi (HITL). AI çözüm aksiyonu uygulandı.", status: :see_other
  end

  def reject_hitl
    @ticket.reject_hitl_action!(
      rejected_by: @ticket.assigned_agent.presence || Ticket::AGENTS.first,
      reason: params[:reason].presence || "Mühendis manuel müdahaleyi tercih etti."
    )
    redirect_to @ticket, alert: "✗ AI önerisi reddedildi. Talep manuel incelemeye alındı.", status: :see_other
  end

  def simulate_agent_incident
    ticket = Ticket.create_from_agent!(
      agent_id: "stripe_payment_worker_v2",
      title: "Ödeme Ağ Geçidi Zaman Aşımı (504 Gateway Timeout)",
      description: "Stripe Webhook 3 ardışık çağrıda zaman aşımına uğradı. 14 adet müşteri ödemesi askıda kaldı.",
      error_code: "STRIPE_504_TIMEOUT",
      context: { service: "checkout-worker", pending_transactions: 14, host: "prod-worker-03" }
    )
    redirect_to ticket, notice: "🤖 Dış AI Agent başarıyla ticket açtı! AI Triage teşhisi koydu ve İnsan Onayı (HITL) bekliyor.", status: :see_other
  end

  def simulate
    return head :forbidden unless Rails.env.development?
    @ticket.simulate_five_hours!
    redirect_to @ticket, notice: "Başlangıç ve SLA son tarihi 5 saat geri alındı.", status: :see_other
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def invalid_action(error)
    redirect_to @ticket, alert: error.record.errors.full_messages.join(", "), status: :see_other
  end
end
