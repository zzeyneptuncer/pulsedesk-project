# PulseDesk

Projenin amacı: PulseDesk - Kurumsal SLA ve Destek Talebi (Ticket) Aort Dilimi.

## Mimari
Rails 8.1, SQLite, Hotwire/Turbo, Stimulus ve temiz modern CSS. Testler Minitest ve ActiveSupport::Testing::TimeHelpers (`travel_to`) kullanır. Temsilciler Ticket::AGENTS sabitinde tanımlıdır. Ek iş mantığı gem'i yoktur.

## İş kurallarının tek adresi: app/models/ticket.rb
- `TRANSITIONS` ve `validate_status_transition`: izin verilen durum geçişleri; doğrudan update! işlemleri de doğrulanır.
- `transition_to!`: kilit altında durum değişikliği.
- `open_on_assignment` / `assign_agent!`: temsilci atanınca yeni talebi açar.
- `calculate_sla_deadline(from_time = Time.current)`: SLA süresini hesaplayan TEK metot. Acil 1, yüksek 4, normal 8, düşük 24 takvim saati. Hafta sonunu hariç tutma değişikliği bu metoda yapılır.
- `set_initial_sla`: oluşturma öncesi ilk son tarihi belirler.
- `sla_breached?`: çözülmüş taleplerde solved_at, diğerlerinde Time.current ile karşılaştırır. Tam eşitlik aşım değildir.
- `sla_remaining_seconds`: kalan/aşılan saniye; çözülen kayıtta süre sabitlenir.
- `stamp_status_change`: çözüm zamanını kaydeder; yeniden açılınca yeni SLA ve ilk yanıt çevrimini başlatır.
- `add_customer_reply!` / `thank_you_only_message?`: teşekkür koruması ve gerçek sorunla yeniden açılma. Yorum, sayaç ve durum tek transaction/kilit içinde güncellenir.
- `add_agent_reply!`: ilk yanıtı damgalar, yeni talebi açar.
- `simulate_five_hours!`: created_at ve sla_due_at değerlerini beş saat geri alır. HTTP aksiyonu yalnız development ortamında açıktır.

## Çalıştırma
```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
bin/rails test
```
Windows PowerShell üzerinde bin/rails yerine `ruby bin/rails` kullanın.
Yerel Windows kurulumundaki önceden derlenmiş SQLite gem'i uyumsuz olduğu için Gemfile SQLite'ın kaynak platformunu seçer; bu makinedeki çalışan yerel derleme kullanılır.

## Sunum
Çözülen örnek talebi açın, teşekkür hızlı testine basın: durum, SLA ve solved_at değişmez; koruma sayacı artar. Sorun hızlı testine basın: açık durumuna geçer, yeni SLA başlar. Yüksek öncelikli açık kayıtta +5 saat düğmesi SLA aşımını gösterir.
Seed tekrar çalıştırıldığında mevcut kayıtları silmez ve aynı başlıklarda çoğaltmaz. Bu uygulama yerel sunum dilimidir; kimlik doğrulama/çok kiracılı erişim kapsam dışındadır.

## Teslim ve dağıtım
- README araştırma bölümünde kaynak markaya atıf yapılabilir; uygulama kodu, arayüz, seed ve logo PulseDesk olarak kalır.
- CI her push/pull_request olayında db:test:prepare ve Minitest çalıştırır.
- render.yaml ücretsiz Ruby Web Service tanımlar. bin/render-build.sh varlıkları derler, veritabanını hazırlar ve seed çalıştırır. bin/render-start.sh her açılışta idempotent seed'i tekrar uygular.
- Ücretsiz Render dosya sistemi geçicidir; SQLite yalnız demo verisi içindir. Sonradan eklenen kayıtlar yeniden başlatmada kaybolabilir.
- db/seeds.rb find_or_create_by! kullanır; yalnız yeni kayıtlara örnek durum/yorum ekler. test/models/seeds_test.rb tekrar çalıştırmanın mevcut verileri koruduğunu doğrular.
