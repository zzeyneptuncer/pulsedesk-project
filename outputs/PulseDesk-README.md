# PulseDesk — Kurumsal Destek ve SLA Aort Dilimi

[![CI](https://github.com/KULLANICI_ADI/REPO_ADI/actions/workflows/ci.yml/badge.svg)](https://github.com/KULLANICI_ADI/REPO_ADI/actions/workflows/ci.yml)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/KULLANICI_ADI/REPO_ADI)

> Rozet ve dağıtım bağlantısındaki `KULLANICI_ADI/REPO_ADI` yer tutucularını kendi GitHub deponuzla değiştirin. Yeşil CI rozeti ancak GitHub üzerinde başarılı bir workflow çalışması sonrasında oluşur. Render dosyaları hazırdır; bu teslimde uzak bir dağıtım yapılmamıştır.

PulseDesk, bir destek talebinin oluşturulmasından çözümüne uzanan aort dilimini uygular: `new → open → pending → solved`, önceliğe bağlı SLA, temsilci/müşteri yanıtları ve akıllı yeniden açılma koruması. Rails 8.1, SQLite, Hotwire/Turbo, Stimulus, özgün SVG logo ve modern CSS kullanır.

## İlham Kaynağı ve Fortune 500 Kanıtı

Bu proje **Zendesk**'in ana iş akışından (aort diliminden) ilham alınarak geliştirilmiştir; uygulama içinde orijinal marka adı ve logosu kullanılmamıştır. Marka adı yalnızca bu README'nin araştırma ve kaynak gösterimi kapsamında yer alır.

Teslim araştırmasında kullanılan ifade: “Zendesk, aralarında Fortune 500 devlerinin de bulunduğu **113.000'den fazla şirket** tarafından kullanılmaktadır.” Kanıt bağlantıları: [Zendesk Kurumsal Müşterileri](https://www.zendesk.com/customer/) ve [TechnologyChecker Zendesk Veri Raporu](https://technologychecker.io/technology/zendesk).

**Kaynak doğrulama notu (16.10.2026):** TechnologyChecker'ın ölçümü 113.696 **alan adı** tespitidir; 69.697 alan adı şirket kaydıyla eşleştirilmiştir. Alan adı sayısı, benzersiz şirket veya ücretli müşteri sayısıyla aynı değildir. Dolayısıyla yukarıdaki 113.000 şirket ifadesi kesin bir müşteri sayısı olarak doğrulanmış değildir.

**Somut Fortune 500 eşleştirmesi:** Labcorp Holdings, Fortune 500'de 326. sıradadır ([resmi Fortune şirket profili](https://fortune.com/company/laboratory-corp-of-america/)). TechnologyChecker'ın aynı raporu `www.ondemand.labcorp.com` üzerinde Zendesk tespiti gösterir. Bu eşleştirme belirli bir şirket hizmetindeki kullanıma işaret eder; tüm şirketin kurumsal lisans kapsamını kanıtlamaz.

## Faz 1 - Küçük Araştırma (Fortune 500 Genel Tablo - Kaynaklı)

### a. Değerleme ve Gelir Aralığı

2026 Fortune 500 listesine giriş barajı (500. sıra) yıllık **7,5 milyar $** gelir iken 1. sıradaki Amazon'un geliri **716,9 milyar $**'dır. Kaynak: [South Fortune 500 2026 Rehberi](https://www.hireinsouth.com/post/what-is-a-fortune-500-company).

Piyasa değerlemesi (Market Cap) için teslim taslağındaki aralık **~1 milyar $–4,24 trilyon $**'dır. [Someka 2026 Fortune 500 Analizi](https://www.someka.net/blog/2026-fortune-500-list-insights/) Nvidia'nın **4,24 trilyon $** değerini desteklemektedir; **~1 milyar $** alt sınırı bu sayfada doğrulanamamıştır ve yaklaşık varsayım olarak tutulmuştur. Piyasa değeri tarihe bağlıdır; gelir sırası piyasa değeri sırası değildir ve özel şirketlerde halka açık piyasa değeri bulunmayabilir.

### b. Çalışan Sayısı Aralığı

Teslim taslağının alt aralık örnekleri **~200 – 400 çalışan**dır: Host Hotels & Resorts ~200, Realty Income ~400 çalışan. Kaynak: [Salt Technologies Fortune 500 Veri Seti](https://www.salttechno.ai/datasets/fortune-500-companies-2025/). Üst uçta Walmart **2,1 milyon çalışan** ile gösterilmektedir. Kaynak: [Someka 2026 Fortune 500 Analizi](https://www.someka.net/blog/2026-fortune-500-list-insights/).

**Karşılaştırma sınırı:** Salt veri seti 2025, Someka analizi 2026 etiketlidir. Salt tablosundaki bazı gelir/sıra değerleri Fortune giriş barajıyla tutarlı değildir. Bu nedenle 200–400 sayıları listede görülen örneklerdir; güncel Fortune 500'ün doğrulanmış minimum çalışan sayısı olarak sunulmaz.

### c. Bir Firmanın Kullandığı SaaS Ürünü Sayısı

Zylo'nun örnekleminde şirketler ortalama **305 SaaS uygulaması** yönetmektedir: [Zylo 2026 SaaS Management Index](https://zylo.com/blog/saas-predictions-for-2026-signal-a-shift-in-spend-and-governance). KOBİ'lerin de dahil olduğu genel pazar karşılaştırması için BetterCloud'un bildirdiği ortalama **118 uygulama**dır: [BetterCloud 2026 State of SaaS](https://www.bettercloud.com/monitor/saas-statistics/).

Bu iki rakam farklı örneklem ve yöntemlere aittir; 305 yalnızca Fortune 500 şirketlerinin ölçümü, 118 ise tüm dünya şirketlerinin sayımı olarak yorumlanmamalıdır.

### d. SaaS Aboneliklerine Yıllık Ödenen Para

10.000+ çalışanlı büyük kurumsal (Fortune 500 ölçeği) firmalar için yıllık **123,5 milyon $–375,5 milyon $** aralığı ve çalışan başına ortanca **9.455 $/yıl** bildirilmiştir: [Carly AI 2026 SaaS İstatistikleri](https://www.usecarly.com/blog/saas-statistics/). Zylo'nun örneklemindeki şirketlerin genel ortalaması yıllık **55,8 milyon $**'dır: [Zylo SaaS Spend Management 2026](https://zylo.com/blog/saas-spend-management).

Carly aynı genel ortalamayı 55,7 milyon $ olarak aktarmaktadır; 55,8 milyon $ değeri burada doğrudan Zylo'ya atfedilmiştir. Büyük çalışan sayısı Fortune 500 üyeliğini tek başına kanıtlamaz; aralık her Fortune 500 şirketinin gerçek harcaması değildir.

## Faz 2 - Maliyet Tahmini

### Orijinal Ürünün Yaklaşık Kod Satırı Sayısı ve Tahmin Yöntemi

Zendesk'in çekirdek platformu için **~350.000 – 500.000+ satır** uygulama kodu bir **ödev ölçek tahminidir**; kapalı kaynak kod tabanı ölçülmemiştir. Yaklaşım; Omnichannel Ticketing, SLA & Triggers Engine, Guide/Knowledge Base, Explore Analytics, RBAC, REST/GraphQL API ve Faturalama modüllerinin her biri için varsayımsal 30.000–50.000 satır Ruby/Rails ve frontend kodu ile ortak altyapı/entegrasyon payını dikkate alır. Yedi modül tek başına 210.000–350.000 satır eder; üst aralık ortak altyapı payı varsayımını gerektirir.

[Zendesk GitHub açık kaynak bileşenleri](https://github.com/zendesk) yöntem için incelenebilecek bağlamdır; bu teslimde depoların satır sayımı yapılmadı. Açık kaynak parçalarından kapalı çekirdeğin kesin boyutu çıkarılamaz.

### Coding Agent ile Çekirdek Üretim Tahmini vs. Gerçekleşen

- **Başlangıç Tahmini (proje sahibinin beyanı):** Aort dilimini üretmenin **2 gün** süreceği ve yaklaşık **15–20 $** tutarında token harcayacağı tahmin edilmişti.
- **Gerçekleşen (proje sahibinin beyanı, bağımsız ölçüm değil):** OpenAI Codex ve Gemini iş birliğiyle aort dilimi, testler ve canlıya alma hazırlığı yaklaşık **2–3 saat** içinde, mevcut **20 $/ay** abonelik kotası dahilinde yaklaşık **~1,50 – 2,00 $** eşdeğeri token maliyetiyle tamamlanmıştır.

**Ölçüm notu:** Bu çalışma kayıtları Codex tarafındaki uygulama ve testleri doğrular; Gemini katkısı, toplam çalışma süresi, abonelik tutarı ve token maliyetine ait sayaç/fatura sunulmamıştır. Yukarıdaki tutarlar kullanıcı beyanıdır; gerçekleşen ölçülmüş maliyet olarak doğrulanmamıştır. Abonelik bedeli ile API token eşdeğeri aynı ölçüm değildir.

## 100 Puanlık Kullanılabilir Pas (Çözülen Kullanıcı Acısı)

### Kaynak Yorumlar

[G2 Zendesk İncelemeleri](https://www.g2.com/products/zendesk-for-customer-service/reviews), [Capterra Zendesk İncelemeleri](https://www.capterra.com/p/164283/Zendesk/reviews/) ve [Featurebase G2 Kullanıcı Analizi](https://www.featurebase.app/blog/zendesk-pros-and-cons).

Kullanıcının teslim metninde sağladığı kısaltılmış alıntı:

> “The Agent workspace is clumsy and inefficient... Ticket views are clunky to create and manage, and contain way too much white space, causing constant scrolling”

Featurebase, çalışma alanı ve gereksiz kaydırmaya ilişkin bu yakınmayı bir G2 yorumuna atfeder. Capterra sayfasının içeriği bu kontrolde alınamadı. Teşekkür yanıtının SLA'yı bozması bu kaynaklarda ayrıca doğrulanmış bir ürün hatası değildir; PulseDesk'in ele aldığı somut iş kuralı senaryosudur. Gerçek ürünlerde yeniden açılma davranışı durum ve otomasyon ayarlarına bağlı olabilir.

### Tek Cümlelik Sunum Özeti

Destek temsilcilerinin G2 yorumlarında şikayet ettiği “hantal, tek ekranda filtrelenemeyen operasyon ekranı” ve çözülmüş (`solved`) bir talebe müşteri sadece “Teşekkürler” yazdığında talebin otomatik olarak tekrar `open` durumuna dönüp SLA süresini bozması acısını, PulseDesk'te **Tek Ekran Hızlı Operasyon Paneli ve Akıllı Teşekkür Koruması (Smart Reopen Guard)** ile çözdük.

### Canlı Gösterim

1. Çözülen talebi açın; “Teşekkürler, sağ olun” müşteri yanıtını gönderin. Durum `solved` kalır; `reopen_prevented_count` artar; SLA ve çözüm zamanı değişmez.
2. “Teşekkürler ama hata devam ediyor” gönderin. Durum `open` olur; önceliğe göre yeni SLA başlar.
3. Yerel geliştirme ortamında yüksek öncelikli açık talepte “Zamanı +5 Saat İleri Sar” düğmesini kullanın; SLA aşımı görünür. Bu zaman değiştirme düğmesi production ortamında kapalıdır.
4. Tek ekranda durum filtreleri, atama, temsilci yanıtı ve çözüm aksiyonlarını gösterin.

## Yapamadıklarım (Kapsam Dışı Bırakılanlar)

- Gerçek e-posta (SMTP/IMAP), telefon ve WhatsApp/Slack omnichannel entegrasyonu (sistem şu an web arayüzü ve müşteri yanıt simülatörü üzerinden çalışmaktadır).
- Çoklu şirket (multi-tenant) izolasyonu, gerçek kullanıcı girişi (authentication) ve rol tabanlı yetkilendirme.
- Resmi tatiller ve hafta sonu mesai saatlerine göre SLA sayacını otomatik duraklatma (şu an 7/24 takvim saati üzerinden hesaplanmaktadır).
- Bilgi bankası (Help Center) makale öneri motoru ve gerçek zamanlı WebSocket (ActionCable) bildirimleri.

## Yerel Kurulum ve Test

Ruby 3.4.7 ve Rails 8.1 kullanılır:

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
bin/rails test
```

Windows PowerShell üzerinde `bin/rails` yerine `ruby bin/rails` kullanın. Yerel adres: http://127.0.0.1:3000.

SQLite kaynak platformu seçilmiştir; yeni bir Windows kurulumunda RubyInstaller Devkit gerekebilir. `Gemfile.lock` Windows ve x86_64 Linux platformlarını içerir.

Minitest ve `ActiveSupport::Testing::TimeHelpers#travel_to` ile geçerli/geçersiz geçişler, SLA sınırı, zamanında çözümün gelecekte de aşılmamış kalması, teşekkür koruması ve gerçek sorunla yeniden açılma doğrulanır. Seed testi iki çalıştırmanın mevcut kayıt ve yorumları değiştirmediğini denetler.

Son yerel sonuç: **18 test, 150 doğrulama, 0 failures, 0 errors, 0 skips**.

## GitHub Actions CI

`.github/workflows/ci.yml`, her `push` ve `pull_request` olayında Linux üzerinde Ruby bağımlılıklarını kurar ve şu komutu çalıştırır:

```sh
bin/rails db:test:prepare && bin/rails test
```

Ardından otomatik yükleme kontrolü (`zeitwerk:check`) yapılır. CI dosyası hazırdır; uzak GitHub çalışması bu yerel test sonucuyla eşdeğer değildir.

## Render.com Deploy Hazırlığı

1. Projeyi kendi GitHub deponuza yükleyin; README'deki iki bağlantının yer tutucularını değiştirin.
2. “Deploy to Render” düğmesini kullanın veya Render'da **New → Blueprint** ile depoyu seçin.
3. `render.yaml`, Ruby çalışma ortamında **Free Web Service** oluşturacak şekilde hazırlanmıştır. `SECRET_KEY_BASE` Render tarafından üretilir; yerel `config/master.key` dosyasını yüklemeyin.
4. Build komutu `bash bin/render-build.sh`: bağımlılıklar, `assets:precompile`, `db:prepare`, `db:seed`.
5. Start komutu `bash bin/render-start.sh`: `db:prepare`, `db:seed`, ardından Render'ın `PORT` değeriyle Puma. Health check: `/up`.

`db/seeds.rb`, `find_or_create_by!` kullanır; yeni oluşturulmayan taleplerin durumunu veya yorumlarını değiştirmez. İlk açılışta beş örnek talep görünür.

**Ücretsiz planın veri sınırı:** Yerel SQLite dosyası restart/redeploy/uyku sonrası kaybolabilir; açılış betiği örnekleri yeniden oluşturur. Kullanıcının sonradan eklediği veriler kalıcı değildir. Kalıcı kayıt gerektiğinde ücretli disk veya ayrı kalıcı veritabanı gerekir. Kaynaklar: [Render Free](https://render.com/docs/free), [Render Rails 8 Deploy](https://render.com/docs/deploy-rails-8). Bu kurulum ödev demosudur; kapsam dışındaki kullanıcı girişi ve yetkilendirme olmadan gerçek müşteri verisi kullanılmaz.

## İş Kuralları Haritası

`app/models/ticket.rb` içindeki `calculate_sla_deadline` SLA politikasının tek adresidir; `sla_breached?` ve `sla_remaining_seconds` süreyi okur. `TRANSITIONS`, `transition_to!` ve `validate_status_transition` durum akışını; `add_customer_reply!` ve `thank_you_only_message?` teşekkür korumasını yönetir. Ayrıntılı mimari ve çalıştırma notları `AGENT.md` dosyasındadır.
