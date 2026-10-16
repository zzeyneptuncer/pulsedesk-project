# Tekrar çalıştırılabilir, mevcut talepleri silmeyen sunum verisi.
examples = [
  { title: "SSO oturum açma hatası", description: "Atlas Finans çalışanları kurumsal kimlik sağlayıcısı üzerinden oturum açamıyor. SAML yanıtlarının incelenmesi gerekiyor.", customer_name: "Selin Arslan · Atlas Finans", customer_email: "selin@atlas.example", priority: "urgent", state: "new", age: 20.minutes },
  { title: "ERP entegrasyonunda sipariş senkronizasyonu", description: "Kuzey Lojistik siparişleri ERP sistemine aktarılırken kuyrukta bekliyor. Son başarılı aktarım sabah 08:30'da gerçekleşti.", customer_name: "Bora Akın · Kuzey Lojistik", customer_email: "bora@kuzey.example", priority: "high", state: "open", age: 5.hours },
  { title: "Aylık kullanım raporunda eksik kayıtlar", description: "Nova Teknoloji ekibi eylül kullanım raporundaki eksik satırları bildirdi. Karşılaştırma dosyası müşteriden bekleniyor.", customer_name: "Duru Şen · Nova Teknoloji", customer_email: "duru@nova.example", priority: "medium", state: "pending", age: 3.hours },
  { title: "Ekip yetkileri ve rol güncellemesi", description: "Mavi Perakende mağaza yöneticilerinin rapor erişimleri güncellendi. Müşteri erişimi doğruladı.", customer_name: "Can Eren · Mavi Perakende", customer_email: "can@mavi.example", priority: "low", state: "solved", age: 6.hours },
  { title: "Ödeme bildirimlerinde gecikme", description: "Vega Ticaret ödeme bildirimleri gecikmeli ulaşıyor. Webhook yeniden deneme yapılandırması gözden geçiriliyor.", customer_name: "İpek Yalçın · Vega Ticaret", customer_email: "ipek@vega.example", priority: "high", state: "open", age: 1.hour }
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
      ticket.add_agent_reply!("Merhaba, talebinizi inceledik. Çözüm sürecini buradan takip edebilirsiniz.", author_name: ticket.assigned_agent)
      ticket.transition_to!(data[:state]) unless data[:state] == "open"
    end
    ticket.add_customer_reply!("Teşekkür ederim, çözüldü!", customer_name: ticket.customer_name) if data[:state] == "solved"
  end
end
puts "PulseDesk hazır: #{Ticket.count} talep, #{TicketComment.count} yorum."
