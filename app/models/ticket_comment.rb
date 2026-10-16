class TicketComment < ApplicationRecord
  belongs_to :ticket
  validates :author_name, :body, presence: true
  validates :body, length: { maximum: 10_000 }
  validates :author_role, inclusion: { in: %w[customer agent] }
end
