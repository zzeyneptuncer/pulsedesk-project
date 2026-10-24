# Tekrar çalıştırılabilir, mevcut talepleri silmeyen sunum verisi.
examples = [
  {
    title: "SSO oturum açma hatası",
    description: "Atlas Finans çalışanları kurumsal kimlik sağlayıcısı üzerinden oturum açamıyor. SAML yanıtlarının incelenmesi gerekiyor.",
    customer_name: "Selin Arslan · Atlas Finans",
    customer_email: "selin@atlas.example",
    priority: "urgent",
    state: "new",
    age: 20.minutes,
    source_type: "human"
  },
  {
    title: "ERP entegrasyonunda sipariş senkronizasyonu",
    description: "Kuzey Lojistik siparişleri ERP sistemine aktarılırken kuyrukta bekliyor. Son başarılı aktarım sabah 08:30'da gerçekleşti.",
    customer_name: "Bora Akın · Kuzey Lojistik",
    customer_email: "bora@kuzey.example",
    priority: "high",
    state: "open",
    age: 5.hours,
    source_type: "human"
  },
  {
    title: "Aylık kullanım raporunda eksik kayıtlar",
    description: "Nova Teknoloji ekibi eylül kullanım raporundaki eksik satırları bildirdi. Karşılaştırma dosyası müşteriden bekleniyor.",
    customer_name: "Duru Şen · Nova Teknoloji",
    customer_email: "duru@nova.example",
    priority: "medium",
    state: "pending",
    age: 3.hours,
    source_type: "human"
  },
  {
    title: "Ekip yetkileri ve rol güncellemesi (Çözüldü - Teste Hazır)",
    description: "Mavi Perakende mağaza yöneticilerinin rapor erişimleri güncellendi. Talep çözüldü durumundadır. Sağ taraftaki 'Samimi Teşekkür' ve 'Sarkastik Teşekkür' butonlarını bu talepte deneyebilirsiniz.",
    customer_name: "Can Eren · Mavi Perakende",
    customer_email: "can@mavi.example",
    priority: "low",
    state: "solved",
    age: 6.hours,
    source_type: "human"
  },
  {
    title: "Ödeme bildirimlerinde gecikme",
    description: "Vega Ticaret ödeme bildirimleri gecikmeli ulaşıyor. Webhook yeniden deneme yapılandırması gözden geçiriliyor.",
    customer_name: "İpek Yalçın · Vega Ticaret",
    customer_email: "ipek@vega.example",
    priority: "high",
    state: "open",
    age: 1.hour,
    source_type: "human"
  },
  {
    title: "[Agent Incident] Stripe Webhook 504 Gateway Timeout",
    description: "Stripe Webhook ödeme bildirim servisi 3 ardışık çağrıda 504 Gateway Timeout aldı. 14 adet müşteri ödemesi askıda kaldı.\n\n[Agent Metadata]\nAgent ID: stripe_payment_worker_v2\nHata Kodu: STRIPE_504_GATEWAY_TIMEOUT\nContext: {\"service\":\"checkout-worker\",\"pending_charges\":14,\"host\":\"prod-worker-03\"}",
    customer_name: "AI Agent (stripe_payment_worker_v2)",
    customer_email: "agent-stripe-worker@system.internal",
    priority: "urgent",
    state: "open",
    age: 15.minutes,
    source_type: "agent",
    source_agent_id: "stripe_payment_worker_v2",
    ai_triage_diagnosis: "Ödeme ağ geçidi API yanıt vermedi (Gateway Timeout). Webhook kuyruğu doldu ve 14 işlem askıda kaldı.",
    ai_proposed_action: "Sistem kritik finansal etkiye sahip. Güvenlik gereği otomatik ödeme retry durduruldu; İnsan Mühendis Onayı (HITL) bekleniyor.",
    hitl_status: "pending_human_approval"
  },
  {
    title: "Sipariş İptal Edilemiyor (Sarkazm Uyarısı Örneği)",
    description: "Müşteri sipariş iptal butonunun çalışmadığını bildirdi ve çözüldükten sonra alaycı bir şikayet mesajı gönderdi.",
    customer_name: "Ayşe Yılmaz · Bireysel Müşteri",
    customer_email: "ayse@example.com",
    priority: "urgent",
    state: "open",
    age: 45.minutes,
    source_type: "human",
    sarcasm_detected: true,
    ai_intent: "sarcastic_complaint",
    ai_sentiment: "frustrated_sarcastic"
  }
]

Ticket.transaction do
  examples.each_with_index do |data, index|
    attributes = data.except(:state, :age)
    ticket = Ticket.find_or_create_by!(title: data[:title]) do |record|
      record.assign_attributes(attributes)
      started = Time.current - data[:age]
      record.created_at = started
      record.sla_due_at = record.calculate_sla_deadline(started)
    end
    next unless ticket.previously_new_record?

    unless data[:state] == "new"
      ticket.assign_agent!(Ticket::AGENTS[index % Ticket::AGENTS.length])
      ticket.add_agent_reply!("Merhaba, talebinizi inceliyoruz. Güncellemeler buradan iletilecektir.", author_name: ticket.assigned_agent)
      ticket.transition_to!(data[:state]) unless data[:state] == "open"
    end

    if data[:title].include?("Sarkazm Uyarısı")
      ticket.ticket_comments.create!(
        author_name: ticket.customer_name,
        author_role: "customer",
        body: "Harika sistem yapmışsınız, 3 gündür çöktü çok teşekkürler!",
        sarcasm_detected: true,
        ai_intent: "sarcastic_complaint",
        ai_confidence: 0.96
      )
    elsif data[:state] == "solved"
      ticket.add_customer_reply!("Teşekkür ederim, erişimler sorunsuz açıldı!", customer_name: ticket.customer_name)
    end
  end
end

puts "PulseDesk hazır: #{Ticket.count} talep, #{TicketComment.count} yorum."
