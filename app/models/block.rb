class Block < ApplicationRecord
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'
  has_one :unblock

  validates :blocked_id,
            comparison: { other_than: :blocker_id },
            uniqueness: { scope: :blocker_id, conditions: -> { active } }

  scope :active, -> { where.missing(:unblock) }

  def readonly?
    persisted?
  end
end
