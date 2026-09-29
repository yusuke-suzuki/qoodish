class Mute < ApplicationRecord
  belongs_to :muter, class_name: 'User'
  belongs_to :muted, class_name: 'User'
  has_one :unmute

  validates :muted_id,
            comparison: { other_than: :muter_id },
            uniqueness: { scope: :muter_id, conditions: -> { active } }

  scope :active, -> { where.missing(:unmute) }

  def readonly?
    persisted?
  end
end
