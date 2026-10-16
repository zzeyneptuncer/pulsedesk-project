module TicketsHelper
  def status_label(status)
    { "new" => "Yeni", "open" => "Açık", "pending" => "Bekleyen", "solved" => "Çözülen" }.fetch(status, status)
  end

  def priority_label(priority)
    { "low" => "Düşük", "medium" => "Normal", "high" => "Yüksek", "urgent" => "Acil" }.fetch(priority)
  end

  def sla_label(ticket)
    seconds = ticket.sla_remaining_seconds.abs
    duration = "#{seconds / 3600} sa #{seconds % 3600 / 60} dk"
    return "SLA AŞILDI · #{duration}" if ticket.sla_breached?
    ticket.status == "solved" ? "SLA içinde çözüldü" : "#{duration} kaldı"
  end
end
