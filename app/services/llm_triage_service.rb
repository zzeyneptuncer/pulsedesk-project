require "net/http"
require "json"
require "uri"

class LlmTriageService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
  DEFAULT_MODEL = "llama-3.1-8b-instant"

  class << self
    def analyze_reply(body:, ticket:)
      new.analyze_reply(body: body, ticket: ticket)
    end

    def triage_incident(title:, description:, error_code: nil, context: {})
      new.triage_incident(title: title, description: description, error_code: error_code, context: context)
    end
  end

  def analyze_reply(body:, ticket:)
    text = body.to_s.strip
    return fallback_empty_reply if text.empty?

    # Groq API anahtarı tanımlıysa canlı LLM çağrısı yap, değilse veya hata olursa akıllı semantik analize dön
    if groq_api_key.present?
      llm_result = call_groq_reply_analysis(text: text, ticket: ticket)
      return llm_result if llm_result.present?
    end

    semantic_local_reply_analysis(text: text, ticket: ticket)
  end

  def triage_incident(title:, description:, error_code: nil, context: {})
    if groq_api_key.present?
      llm_result = call_groq_incident_triage(title: title, description: description, error_code: error_code, context: context)
      return llm_result if llm_result.present?
    end

    semantic_local_incident_triage(title: title, description: description, error_code: error_code, context: context)
  end

  private

  def groq_api_key
    ENV["GROQ_API_KEY"].presence
  end

  def call_groq_reply_analysis(text:, ticket:)
    prompt = <<~PROMPT
      Sen kurumsal bir müşteri destek ve SLA yöneticisi olan yapay zeka asistanısın.
      Aşağıdaki müşteri yanıtını analiz et. Müşterinin yanıtı gerçekten sorunun çözüldüğüne dair samimi bir teşekkür mü ("genuine_gratitude"),
      yoksa görünürde teşekkür edip alaycı/sarkastik bir şekilde şikayet mi ediyor ("sarcastic_complaint"),
      yoksa devam eden bir sorunu mu açıkça anlatıyor ("ongoing_issue")?

      Örnek sarkazm: "Harika sistem yapmışsınız 3 gündür çöktü çok teşekkürler", "Sayenizde battık elinize sağlık", "Süper çalışıyor ama hiçbir şey açılmıyor".
      Örnek samimi teşekkür: "Teşekkürler sorun çözüldü", "Elinize sağlık çok yardımcı oldunuz", "Harika süper teşekkürler".
      Örnek açık sorun: "Teşekkürler ama hata devam ediyor", "Hâlâ çalışmıyor".

      Mevcut talep başlığı: #{ticket.title}
      Müşteri mesajı: "#{text}"

      Yalnızca şu JSON formatında yanıt ver, başka hiçbir metin ekleme:
      {
        "intent": "genuine_gratitude" veya "sarcastic_complaint" veya "ongoing_issue",
        "sarcasm_detected": true veya false,
        "sentiment": "positive" veya "frustrated_sarcastic" veya "negative" veya "neutral",
        "confidence": 0.0 ile 1.0 arası float,
        "should_prevent_reopen": true veya false (sadece samimi teşekkür ise true, sarkazm veya arıza varsa false),
        "escalate_priority": "urgent" veya null (yalnızca sarkazm veya kriz varsa "urgent"),
        "reasoning": "Kısa Türkçe açıklama"
      }
    PROMPT

    response = query_llm(prompt)
    parse_json_response(response)
  rescue => e
    Rails.logger.warn("Groq LLM analizi başarısız, semantik fallback devrede: #{e.message}")
    nil
  end

  def call_groq_incident_triage(title:, description:, error_code:, context:)
    prompt = <<~PROMPT
      Sen otonom yazılım agent'ları ve monitoring sistemlerinden gelen arıza ticket'larını inceleyen bir AI Triage Mühendisisin.
      Aşağıdaki incident raporunu analiz et:

      Başlık: #{title}
      Açıklama: #{description}
      Hata Kodu: #{error_code}
      Ek Bağlam: #{context.to_json}

      Yalnızca şu JSON formatında yanıt ver:
      {
        "priority": "urgent" veya "high" veya "medium" veya "low",
        "diagnosis": "Arızanın kök neden analizi (Türkçe)",
        "proposed_action": "Önerilen çözüm veya telafi aksiyonu (Türkçe)",
        "requires_human_approval": true veya false (finansal, güvenlik veya veri kaybı riski varsa true),
        "confidence": 0.0 ile 1.0 arası float
      }
    PROMPT

    response = query_llm(prompt)
    parse_json_response(response)
  rescue => e
    Rails.logger.warn("Groq LLM Incident analizi başarısız, semantik fallback devrede: #{e.message}")
    nil
  end

  def query_llm(prompt)
    uri = URI.parse(GROQ_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5
    http.open_timeout = 3

    request = Net::HTTP::Post.new(uri.path, {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{groq_api_key}"
    })

    request.body = {
      model: DEFAULT_MODEL,
      messages: [{ role: "user", content: prompt }],
      temperature: 0.1,
      response_format: { type: "json_object" }
    }.to_json

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    parsed.dig("choices", 0, "message", "content")
  end

  def parse_json_response(content)
    return nil if content.blank?
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    nil
  end

  # Yerel semantik motor: LLM API erişilemediğinde veya testlerde çalışan akıllı kural/niyet çözümleyici
  def semantic_local_reply_analysis(text:, ticket:)
    normalized = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace).unicode_normalize(:nfkc).downcase.tr("ı", "i")

    # 1. Açık Karşıtlık / Sorun İfadesi ("ama", "fakat", "ancak", "çalışmıyor" vb.)
    # Müşteri "ama hata var" diyorsa bu sarkazm değil, doğrudan devam eden sorundur.
    explicit_issue_keywords = /\b(ama|fakat|ancak|lakin|but|devam ediyor|still)\b|çalışmıyor|calismiyor|çözülmedi|olmadi|koptu/
    if normalized.match?(explicit_issue_keywords) || text.include?("?")
      return {
        intent: "ongoing_issue",
        sarcasm_detected: false,
        sentiment: "negative",
        confidence: 0.95,
        should_prevent_reopen: false,
        escalate_priority: nil,
        reasoning: "Müşteri sorunun devam ettiğini veya yeni bir hata/soru olduğunu açıkça belirtti. Talep normal SLA ile yeniden açıldı."
      }
    end

    # 2. Gerçek Sarkazm & Alaycı Kriz Tespiti (Övgü veya teşekkür arkasında felaket gizleme)
    sarcasm_triggers = [
      /harika.*(çöktü|kapalı|battık|mahvoldu)/,
      /süper.*(çöktü|kapalı|bozuldu|açılmıyor)/,
      /teşekkür.*(çöktü|battık|ulaşamıyoruz|mahvettiniz)/,
      /elinize sağlık.*(çöktü|mahvoldu|bozuldu|açılmıyor)/,
      /sağ olun.*(sayenizde|battık|çöktü|zarar)/,
      /sayenizde.*(battık|zarar|çöktü)/
    ]

    has_sarcasm = sarcasm_triggers.any? { |pattern| normalized.match?(pattern) }

    if has_sarcasm
      return {
        intent: "sarcastic_complaint",
        sarcasm_detected: true,
        sentiment: "frustrated_sarcastic",
        confidence: 0.96,
        should_prevent_reopen: false,
        escalate_priority: "urgent",
        reasoning: "Müşteri teşekkür/övgü kalıpları ardında alaycı ve yüksek derecede öfkeli bir kriz bildirimi yapıyor. SLA acile yükseltildi."
      }
    end

    # 3. Samimi Teşekkür ve Çözüm Onayı Tespiti
    gratitude_phrases = /teşekkürler|teşekkür ederim|teşekkür ederiz|tesekkurler|tesekkur ederim|tesekkur ederiz|sağ olun|sağ ol|sağol|sag olun|sag ol|sagol|thanks|thank you|harika|süper|super|çözüldü|cozuldu|tamamen|gerçekten|gercekten|kesinlikle|artık|artik|sorun|problem|düzeldi|duzeldi|tamam|çok|cok|evet|işe yaradi|ise yaradi|her şey yolunda|her sey yolunda|eline sağlık|eline sağlik|eline saglik|elinize sağlık|elinize sağlik|elinize saglik/
    remainder = normalized.gsub(gratitude_phrases, "").gsub(/[\s[:punct:]👍🙏😊✨🎉]+/, "")

    if normalized.match?(gratitude_phrases) && remainder.empty?
      return {
        intent: "genuine_gratitude",
        sarcasm_detected: false,
        sentiment: "positive",
        confidence: 0.98,
        should_prevent_reopen: true,
        escalate_priority: nil,
        reasoning: "Müşteri içten bir teşekkür ile çözümü teyit etti. Talep çözülmüş (solved) durumunda korundu."
      }
    end

    # 4. Genel Müşteri Yanıtı
    {
      intent: "general_reply",
      sarcasm_detected: false,
      sentiment: "neutral",
      confidence: 0.75,
      should_prevent_reopen: false,
      escalate_priority: nil,
      reasoning: "Genel müşteri mesajı algılandı; talep açık duruma getirildi."
    }
  end

  def semantic_local_incident_triage(title:, description:, error_code:, context:)
    combined = "#{title} #{description} #{error_code}".downcase

    is_critical = combined.match?(/database|veritabanı|ödeme|stripe|payment|auth|security|deadlock|500|fatal/)
    priority = is_critical ? "urgent" : "high"

    diagnosis = if combined.include?("payment") || combined.include?("stripe")
      "Ödeme ağ geçidi API yanıt vermedi (Gateway Timeout). Dış servis gecikmesi veya geçersiz API gizli anahtarı."
    elsif combined.include?("database") || combined.include?("deadlock")
      "Veritabanı bağlantı havuzu tükendi (ConnectionPoolExhausted) veya eşzamanlı kilitlenme."
    else
      "Otonom mikroservis işlemi sırasında beklenmeyen çalışma zamanı arızası tespit edildi."
    end

    proposed_action = if is_critical
      "Sistem kritik etkiye sahip. Güvenlik ve veri tutarlılığı gereği otomatik aksiyon bekletildi; İnsan Onayı (HITL) şarttır."
    else
      "Bağlantı havuzunu yeniden başlat ve servis kuyruğunu kontrollü yeniden dene (Retry 3x)."
    end

    {
      priority: priority,
      diagnosis: diagnosis,
      proposed_action: proposed_action,
      requires_human_approval: is_critical,
      confidence: is_critical ? 0.76 : 0.91
    }
  end

  def fallback_empty_reply
    {
      intent: "empty",
      sarcasm_detected: false,
      sentiment: "neutral",
      confidence: 1.0,
      should_prevent_reopen: false,
      escalate_priority: nil,
      reasoning: "Boş yanıt"
    }
  end
end
