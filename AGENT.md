# PulseDesk — Agent-First Destek & Kurumsal SLA Omurgası

Projenin amacı: PulseDesk - Kurumsal SLA, LLM Semantik Triage ve Agent-to-Agent Destek Omurgası.

## Mimari
Rails 8.1, SQLite, Hotwire/Turbo, Stimulus ve modern CSS.
Testler Minitest ve ActiveSupport::Testing::TimeHelpers (`travel_to`) kullanır.
Harici bağımlılık olmadan standard library ile çalışan hibrit LLM servisi (`app/services/llm_triage_service.rb`) ve Agent REST API (`/api/v1/agent/tickets`) içerir.

## İş Kurallarının Adresleri

### 1. Model: `app/models/ticket.rb`
- `TRANSITIONS` ve `validate_status_transition`: İzin verilen durum geçişleri; doğrudan `update!` işlemleri de doğrulanır.
- `calculate_sla_deadline`: SLA süresini hesaplayan TEK metot. Urgent: 1 saat, High: 4 saat, Medium: 8 saat, Low: 24 saat.
- `add_customer_reply!`: Gelen müşteri yanıtını `LlmTriageService` ile analiz eder. Samimi teşekkür ise çözümü korur (`reopen_prevented_count += 1`); sarkastik öfke ise talebi `open` yapar ve SLA'i derhal `urgent` seviyesine yükseltir (`sarcasm_detected = true`).
- `create_from_agent!`: Harici izleme ve yazılım botlarının API üzerinden incident açmasını sağlar. Otomatik AI Triage teşhisi koyar ve kritik durumlarda `pending_human_approval` (HITL) bayrağını kaldırır.
- `approve_hitl_action!` & `reject_hitl_action!`: İnsan mühendisin AI teşhisini onaylamasını veya reddetmesini yönetir.

### 2. Servis: `app/services/llm_triage_service.rb`
- `analyze_reply`: Groq API (Llama 3) veya akıllı yerel semantik motor üzerinden niyet analizi (samimi teşekkür vs. alaycı sarkazm) yapar.
- `triage_incident`: Gelen makine arıza raporlarını inceleyerek kök neden teşhisi koyar ve insan onayı gerekip gerekmediğini belirler.

### 3. API: `app/controllers/api/v1/agent/tickets_controller.rb`
- `POST /api/v1/agent/tickets`: JSON kabul eden harici agent endpoint'i.

## Çalıştırma ve Test
```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
bin/rails test
```
Windows PowerShell üzerinde `ruby bin/rails test` kullanın.
Son test sonucu: **25 test, 189 assertion, 0 failure, 0 error, 0 skips**.

## Render Dağıtımı ve Coding Agent Kuralları
- `render.yaml`: Free Web Service tanımı içerir.
- `bin/render-build.sh`: Varlıkları derler (`assets:precompile`), veritabanı migration'larını çalıştırır ve seed uygular.
- `bin/render-start.sh`: Her açılışta idempotent veritabanını hazırlar ve Puma'yı Render `PORT` değeriyle başlatır.
- Coding agent bu dosyaları okuyarak Render ortamına tam uyumlu derleme ve başlatma betiklerini yapılandırmıştır.
