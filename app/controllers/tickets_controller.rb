class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show transition assign reply simulate]
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_action

  def index
    @total = Ticket.count
    @breached = Ticket.breached.count
    @solved = Ticket.where(status: "solved").count
    @protected = Ticket.sum(:reopen_prevented_count)
    @filter = params[:filter].to_s
    @tickets = Ticket.order(updated_at: :desc)
    @tickets = @tickets.where(status: @filter) if Ticket::STATUSES.include?(@filter)
    @tickets = @tickets.breached if @filter == "breached"
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
      message = comment.prevented_reopen? ? "Teşekkür filtresi çözümü korudu. SLA değişmedi." : "Müşteri yanıtı kaydedildi."
    else
      return redirect_to @ticket, alert: "Geçersiz yanıt rolü.", status: :see_other
    end
    redirect_to @ticket, notice: message, status: :see_other
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
