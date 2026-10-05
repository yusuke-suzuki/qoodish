class Mute < ApplicationRecord
  PER_PAGE = 50
  belongs_to :muter, class_name: 'User'
  belongs_to :muted, class_name: 'User'
  has_one :unmute

  validates :muted_id,
            comparison: { other_than: :muter_id },
            uniqueness: { scope: :muter_id, conditions: -> { active } }

  scope :active, -> { where.missing(:unmute) }

  scope :latest_per_muted, lambda { |next_id = nil|
    page = active
           .select(:muted_id, 'MAX(mutes.id) AS id')
           .group(:muted_id)
           .order('MAX(mutes.id) DESC')
           .limit(PER_PAGE)
    next_id.present? ? page.having('MAX(mutes.id) < ?', next_id) : page
  }

  def self.next_cursor(page)
    page.to_a.last.id.to_s if page.to_a.size == PER_PAGE
  end

  def readonly?
    persisted?
  end
end
