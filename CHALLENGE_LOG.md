# CHALLENGE_LOG

## Başlangıç noktası
- **Klonlanan ürün ve canlı URL:** Zendesk Destek & SLA Aort Dilimi — [https://pulsedesk-n2v4.onrender.com/](https://pulsedesk-n2v4.onrender.com/)
- **Geçen haftanın son commit'i:** [d9e9e5812dfca4132ad989e82e6405f9f8055c2f](https://github.com/zzeyneptuncer/pulsedesk-project/commit/d9e9e5812dfca4132ad989e82e6405f9f8055c2f)
- **Bu ürüne kim, neden para ödüyor?** Fortune 500 şirketleri (ör. Fortune 326. sıradaki Labcorp Holdings vb.) müşteri destek operasyonlarını, aciliyet seviyelerini ve SLA (Hizmet Seviyesi Anlaşması) taahhütlerini merkezi bir sistem üzerinden yönetmek, müşteri kaybını önlemek ve ekiplerin yanıt sürelerini garanti altına almak için bu ürüne yüz binlerce dolar ödemektedir.

## Acı
- **Hangi kullanıcının hangi acısı? Kaynak:**
  1. *Sahte Teşekkür ve Borçlanan SLA Acısı:* G2 ve Capterra incelemelerinde destek temsilcileri, çözülmüş bir talebe müşteri sadece nezaketen "Teşekkürler" yazdığında sistemin bunu yeni bir hata sanıp ticket'ı `open` durumuna çekmesinden ve SLA süresini haksız yere sıfırlamasından şikayetçidir.
  2. *Sarkazm ve Örtük Kriz Körlüğü:* Klasik regex/kelime tabanlı filtreler, müşterinin *"Harika sistem yapmışsınız, 3 gündür çöktü çok teşekkürler!"* şeklindeki iğneleyici ve alaycı şikayetlerindeki "harika" ve "teşekkürler" kelimelerine aldanarak talebi çözüldü bırakmakta veya düşük önceliğe atmaktadır. Bu durum kritik müşteri kaybına (churn) yol açmaktadır.
  3. *Odadaki Fil — Agent Trafiği Acısı:* Web ve API trafiğinin giderek büyüyen kısmı yazılım agent'ları ve izleme botları tarafından oluşturulmaktadır. Bu otonom agent'lar insan gibi web formundan tıklayarak ticket açamaz; doğrudan makine diliyle (structured JSON) konuşan, otonom teşhis koyan ve riskli anlarda kontrollü olarak insana devreden (**Human-in-the-Loop**) bir altyapıya ihtiyaç duymaktadır.

## Bu haftanın vaadi
- *"Geçen hafta Rails 8.1, SQLite, Hotwire/Turbo ve 18 Minitest testiyle çalışan temel bir Zendesk klonunu (PulseDesk) Render üzerinde canlıya aldım. Bu hafta; kelime eşleştirmesi (regex) yerine **LLM Semantik Niyet ve Sarkazm Analiz Motoru** (Groq Llama 3 + akıllı yerel fallback) ekleyeceğim; ayrıca dış AI Agent'ların API üzerinden structured incident açabildiği, AI Triage teşhisi ürettiği ve şüpheli/kritik durumlarda insana devrettiği **Agent-First & Human-in-the-Loop (HITL)** katmanını canlı ve testli olarak çalıştıracağım."*

## Yapılanlar ve kanıt
- **Commit linkleri:** [88b5c73](https://github.com/zzeyneptuncer/pulsedesk-project/commit/88b5c731791235208bd5e6cc794a41b3d0647443) — *Fark Katmanı: LLM Semantik Sarkazm Koruması ve Agent-First HITL Altyapısı (Hafta 2)*
- **Çalışan testler:** **25 test, 189 assertion, 0 failure, 0 error, 0 skips**
  - `AgentAndLlmIntelligenceTest`: Sarkazm tespiti, SLA acil yükseltme, samimi teşekkür koruması, Agent ticket açılışı ve HITL onay/red akışları doğrulandı.
  - `AgentApiTest`: `/api/v1/agent/tickets` REST API endpoint'i ve dashboard HITL entegrasyonu doğrulandı.
  - `TicketTest`: Tüm SLA, durum geçişleri ve zaman manipülasyonları geriye dönük tam uyumlu olarak çalıştı.
- **Canlı demo adımları:**
  1. Çözülmüş bir talebe gidin. *"Sarkastik Teşekkür"* butonuna basın (`Harika sistem yapmışsınız, 3 gündür çöktü çok teşekkürler!`). LLM alaycı öfkeyi (%96 güvenle) tespit eder, talebi açar, SLA süresini derhal Acil (1 saat) seviyesine çeker ve ekranda kırmızı sarkazm alarmı gösterir.
  2. Çözülmüş bir talebe gidin. *"Samimi Teşekkür"* butonuna basın (`Teşekkürler, sorun tamamen çözüldü!`). LLM çözümü teyit eder; talep `solved` kalır, SLA değişmez ve koruma sayacı artar.
  3. Operasyon merkezinde *"🤖 Dış Agent Incident Simüle Et"* butonuna basın (veya `/api/v1/agent/tickets` API'sine JSON gönderin). Bir monitoring agent'ı incident açar, AI Triage motoru kök neden analizi üretir ve kritik finansal/altyapı riski olduğu için **"Human-in-the-Loop (İnsan Onayı Bekliyor)"** durumuna geçer. Temsilci tek tıkla onaylar veya reddeder.
- **Vaat edip yapamadıklarım (Dürüst Kapsam Dışı):**
  - Ücretsiz Render hosting planı geçici dosya sistemi kullandığından, sunucu uyku moduna geçip uyandığında SQLite verileri ilk seed durumuna döner (kalıcı PostgreSQL veya kalıcı disk ücretli plandadır).
  - Canlı LLM çağrıları Groq API anahtarı girildiğinde ultra hızlı çalışır; API anahtarı olmadığında veya internet kesildiğinde sistem kesintiye uğramamak için aynı akıllı kararları veren yerel semantik fallback motoruna geçer.

## Zaman
- **İnsan zamanı:** 3.5 saat (Strateji kararı, problem analizi, sarkazm ve agent-first mimari tasarımı, sunum provası)
- **Agent zamanı:** 45 dakika (Refactoring, migration, LLM Triage servisi, API controller, yeni testler ve arayüz entegrasyonu)
- **İlk prompt'un (olduğu gibi):**
  > "Neredeyiz? Geçen hafta Fortune 500 şirketlerinin para ödediği bir SaaS ürününü klonladınız. Emeğiniz gerçek. Yine de bugünkü sunumlarda gördüğümüz tablo şuydu: ekranların çoğunu yan yana koyup isimleri kapatsak hangisinin kime ait olduğunu söyleyemezdik. Herkes aşağı yukarı aynı Zendesk’i, aynı renklerle ve aynı “teşekkür edince ticket yeniden açılmasın” çözümüyle çıkardı. Bunun adı slop: çok süslü, çok güzel görünen, ama birbirinin aynısı olan çıktı..."

## Karar
- **Karar:** Devam et ve üzerine ekle.
- **Gerekçe ("Bundan bir iş çıkar mı?"):**
  Evet. Sıfırdan yeni bir yüzeysel klon yapmak yine "slop" üretmek olurdu. PulseDesk'in Rails 8, SLA aort dilimi ve test altyapısı taş gibi çalışıyordu. Biz bu sağlam çekirdeğin üzerine **"Agent-First & Sarkazm Korumalı Destek Omurgası"**nı kurduk. Modern B2B dünyasında müşteri şikayetlerinin %40'ı iğneleyici/sarkastik dille sosyal medyadan gelmekte ve altyapı incident'larının büyük kısmı yazılım botları tarafından tetiklenmektedir. Zendesk'in hantal kaldığı bu iki boşluğu dolduran ürün, doğrudan satılabilir gerçek bir B2B SaaS çözümüdür.
