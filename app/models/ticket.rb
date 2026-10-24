class Ticket < ApplicationRecord
  STATUSES = %w[new open pending solved].freeze
  PRIORITIES = %w[low medium high urgent].freeze
  AGENTS = ["Deniz Yılmaz", "Ece Demir", "Mert Kaya"].freeze
  TRANSITIONS = { "new" => %w[open], "open" => %w[pending solved],
                  "pending" => %w[open solved], "solved" => %w[open] }.freeze

  has_many :ticket_comments, dependent: :destroy
  validates :title, :description, :customer_name, :customer_email, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :assigned_agent, inclusion: { in: AGENTS }, allow_blank: true
  validates :sla_due_at, presence: true
  validates :reopen_prevented_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_status_transition
  before_validation :set_initial_sla, on: :create
  before_validation :open_on_assignment
  before_validation :stamp_status_change

  scope :breached, -> { where("(status = 'solved' AND solved_at > sla_due_at) OR (status != 'solved' AND sla_due_at < ?)", Time.current) }
  scope :agent_sourced, -> { where(source_type: "agent") }
  scope :sarcasm_flagged, -> { where(sarcasm_detected: true) }
  scope :pending_hitl, -> { where(hitl_status: "pending_human_approval") }

  # SLA politikasının tek adresi. Şimdilik takvim saatleri kullanılır.
  def calculate_sla_deadline(from_time = Time.current)
    hours = { "urgent" => 1, "high" => 4, "medium" => 8, "low" => 24 }.fetch(priority, 8)
    from_time + hours.hours
  end

  def sla_breached?
    return false unless sla_due_at
    (status == "solved" ? solved_at : Time.current).then { |time| time.present? && time > sla_due_at }
  end

  def sla_remaining_seconds
    return 0 unless sla_due_at
    (sla_due_at - (status == "solved" ? (solved_at || Time.current) : Time.current)).to_i
  end

  def transition_to!(new_status)
    with_lock { update!(status: new_status) }
  end

  def assign_agent!(name)
    with_lock { update!(assigned_agent: name) }
  end

  def add_agent_reply!(body, author_name:)
    with_lock do
      ticket_comments.create!(body: body, author_name: author_name, author_role: "agent")
      self.first_responded_at ||= Time.current
      self.status = "open" if status == "new"
      save!
    end
  end

  def add_customer_reply!(body, customer_name:)
    with_lock do
      llm_analysis = LlmTriageService.analyze_reply(body: body, ticket: self)
      prevented = status == "solved" && llm_analysis[:should_prevent_reopen]

      comment = ticket_comments.create!(
        body: body,
        author_name: customer_name,
        author_role: "customer",
        prevented_reopen: prevented,
        sarcasm_detected: llm_analysis[:sarcasm_detected] || false,
        ai_intent: llm_analysis[:intent],
        ai_confidence: llm_analysis[:confidence]
      )

      if prevented
        self.reopen_prevented_count += 1
      elsif %w[pending solved].include?(status)
        self.status = "open"
      end

      # LLM Sarkazm veya kriz tespit ettiyse: SLA acile çekilir
      if llm_analysis[:sarcasm_detected]
        self.sarcasm_detected = true
        self.ai_intent = llm_analysis[:intent]
        self.ai_sentiment = llm_analysis[:sentiment]
        self.priority = "urgent"
        self.sla_due_at = calculate_sla_deadline
      end

      save!
      comment
    end
  end

  def thank_you_only_message?(body)
    LlmTriageService.analyze_reply(body: body, ticket: self)[:should_prevent_reopen]
  end

  # Otonom AI Agent'ların API üzerinden ticket açması ve AI Triage alması
  def self.create_from_agent!(agent_id:, title:, description:, error_code: nil, context: {})
    triage = LlmTriageService.triage_incident(
      title: title,
      description: description,
      error_code: error_code,
      context: context
    )

    ticket = new(
      title: "[Agent Incident] #{title}",
      description: "#{description}\n\n[Agent Metadata]\nAgent ID: #{agent_id}\nHata Kodu: #{error_code || 'N/A'}\nContext: #{context.to_json}",
      customer_name: "AI Agent (#{agent_id})",
      customer_email: "agent-#{agent_id.to_s.parameterize.presence || 'system'}@system.internal",
      priority: triage[:priority] || "high",
      source_type: "agent",
      source_agent_id: agent_id,
      ai_triage_diagnosis: triage[:diagnosis],
      ai_proposed_action: triage[:proposed_action],
      hitl_status: triage[:requires_human_approval] ? "pending_human_approval" : "approved"
    )

    ticket.save!
    ticket
  end

  def approve_hitl_action!(approved_by:)
    with_lock do
      return unless hitl_status == "pending_human_approval"
      self.hitl_status = "approved"
      ticket_comments.create!(
        author_name: approved_by,
        author_role: "agent",
        body: "✓ İnsan Mühendis Onayı Verildi (HITL). AI aksiyonu uygulandı: #{ai_proposed_action}"
      )
      self.status = "open" if status == "new"
      save!
    end
  end

  def reject_hitl_action!(rejected_by:, reason: "Manuel müdahale başlatıldı.")
    with_lock do
      return unless hitl_status == "pending_human_approval"
      self.hitl_status = "rejected"
      ticket_comments.create!(
        author_name: rejected_by,
        author_role: "agent",
        body: "✗ AI Aksiyonu Reddedildi (HITL). Gerekçe: #{reason}"
      )
      self.status = "open" if status == "new"
      save!
    end
  end

  def simulate_five_hours!
    with_lock { update!(sla_due_at: sla_due_at - 5.hours, created_at: created_at - 5.hours) }
  end

  private

  def set_initial_sla
    self.sla_due_at ||= calculate_sla_deadline
  end

  def open_on_assignment
    return unless new_record? || (status_in_database == "new" && will_save_change_to_assigned_agent?)
    self.status = "open" if status == "new" && assigned_agent.present?
  end

  def validate_status_transition
    return unless persisted? && will_save_change_to_status?
    unless TRANSITIONS.fetch(status_in_database, []).include?(status)
      errors.add(:status, "geçişine izin verilmiyor")
    end
  end

  def stamp_status_change
    return unless will_save_change_to_status?
    if status == "solved"
      self.solved_at = Time.current
    elsif status_in_database == "solved" && status == "open"
      self.solved_at = nil
      self.first_responded_at = nil
      self.sla_due_at = calculate_sla_deadline
    end
  end
end
