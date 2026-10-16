# PulseDesk — Teslim ve sunum haritası

Rails 8.1.1, Ruby 3.4.7, SQLite, Turbo, Stimulus ve özgün modern CSS ile proje mevcut dizinde oluşturuldu. Uygulama http://127.0.0.1:3000 adresinde çalışıyor.

## Oluşturulan başlıca dosyalar

Tüm yolların kökü: `C:/Users/HP/Documents/Codex/2026-10-16/sen-k-demli-bir-ruby-on/`

| Dosya | İçerik |
|---|---|
| AGENT.md | Mimari kararlar, iş kuralları haritası, çalıştırma/test komutları |
| README.md | Kurulum ve canlı sunum akışı |
| app/models/ticket.rb | Durum geçişleri, SLA, yanıtlar ve teşekkür koruması |
| app/models/ticket_comment.rb | Yorum ilişkisi ve doğrulamalar |
| db/migrate/20261016000100_create_tickets.rb | Ticket ve TicketComment tabloları, varsayılanlar, indeks ve foreign key |
| db/schema.rb | Oluşturulan SQLite şeması |
| db/seeds.rb | Tekrar çalıştırılabilen beş kurumsal örnek talep |
| app/controllers/tickets_controller.rb | Liste, detay, oluşturma, atama, durum, yanıt ve simülasyon aksiyonları |
| app/helpers/tickets_helper.rb | Türkçe etiketler ve SLA süre gösterimi |
| app/views/tickets/index.html.erb | Özet kartlar, durum filtreleri ve talep tablosu |
| app/views/tickets/show.html.erb | Akış, konuşma, atama ve hızlı test butonları |
| app/views/tickets/new.html.erb | Yeni talep oluşturma formu |
| app/views/tickets/_sla.html.erb | Ortak SLA rozeti |
| app/views/layouts/application.html.erb | Ürün kabuğu ve navigasyon |
| app/assets/stylesheets/application.css | Duyarlı özgün tasarım |
| app/javascript/controllers/sla_controller.js | Canlı SLA sayacı ve aşım rengi |
| public/icon.svg | Özgün PulseDesk nabız logosu |
| test/models/ticket_test.rb | SLA sınırları, geçiş matrisi, koruma ve transaction testleri |
| test/controllers/tickets_controller_test.rb | Ekranlar ve HTTP aksiyonlarının entegrasyon testleri |
| config/routes.rb | Uygulama yolları |
| config/application.rb | Rails 8.1 ve İstanbul saat dilimi |
| config/importmap.rb | Yerel Hotwire/Stimulus importları |
| Gemfile / Gemfile.lock | Standart Rails bağımlılıkları |
| .github/workflows/ci.yml / config/ci.rb | Test ve otomatik yükleme kontrolleri |

## Ticket modelindeki canlı sunum adresleri

Dosya: `C:/Users/HP/Documents/Codex/2026-10-16/sen-k-demli-bir-ruby-on/app/models/ticket.rb`

| Kural / metot | Satırlar |
|---|---:|
| TRANSITIONS | 5–6 |
| calculate_sla_deadline | 24–27 |
| sla_breached? | 29–32 |
| sla_remaining_seconds | 34–37 |
| transition_to! | 39–41 |
| assign_agent! | 43–45 |
| add_agent_reply! | 47–54 |
| add_customer_reply! | 56–69 |
| thank_you_only_message? | 72–79 |
| simulate_five_hours! | 81–83 |
| set_initial_sla | 87–89 |
| open_on_assignment | 91–94 |
| validate_status_transition | 96–101 |
| stamp_status_change | 103–112 |

“Hafta sonunu saymasın” değişikliğinin tek adresi: calculate_sla_deadline, satır 24–27. Mevcut sürüm takvim saati kullanır.

## Doğrulama

- `ruby bin/rails db:prepare` başarılı.
- `ruby bin/rails db:seed` başarılı; tekrar çalıştırıldığında beş kayıt korunur.
- `ruby bin/rails test`: **16 test, 123 doğrulama, 0 hata, 0 başarısızlık**.
- `ruby bin/rails zeitwerk:check`: başarılı.
- Uygulama kaynaklarında yasaklanan marka için tarama: eşleşme yok.
- Tarayıcıda dashboard ve detay ekranları açıldı; konsolda hata/uyarı yok.
- Canlı teşekkür testi: çözülen durum korundu, sayaç 1 → 2 oldu ve SLA değişmedi.
- Canlı gerçek sorun testi: talep açıldı, yeni SLA başladı; sonrasında tekrar çözüldü.
- Canlı +5 saat testi: açık yüksek öncelikli kayıtta SLA aşımı göründü.
- Son sunum verisi: 5 talep, 1 çözülen, 2 SLA aşımı, 2 koruma olayı. Canlı test yorumları konuşma geçmişinde bırakıldı.

## Çalıştırma

```powershell
bundle install
ruby bin/rails db:prepare
ruby bin/rails db:seed
ruby bin/rails server
ruby bin/rails test
```

Unix ortamında `ruby bin/rails` yerine doğrudan `bin/rails` kullanılabilir.
Yerel Windows SQLite ikili paketi uyumsuz bulundu; Gemfile kaynak platformunu seçerek mevcut çalışan yerel derlemeyi kullanır.
