class Block < ApplicationRecord
  PER_PAGE = 50
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'
  has_one :unblock

  validates :blocked_id,
            comparison: { other_than: :blocker_id },
            uniqueness: { scope: :blocker_id, conditions: -> { active } }

  after_create :remove_bookmarks, :remove_coauthorships, :decline_coauthorship_invitations

  scope :active, -> { where.missing(:unblock) }

  scope :latest_per_blocked, lambda { |next_id = nil|
    page = active
           .select(:blocked_id, 'MAX(blocks.id) AS id')
           .group(:blocked_id)
           .order('MAX(blocks.id) DESC')
           .limit(PER_PAGE)
    next_id.present? ? page.having('MAX(blocks.id) < ?', next_id) : page
  }

  def self.next_cursor(page)
    page.to_a.last.id.to_s if page.to_a.size == PER_PAGE
  end

  def readonly?
    persisted?
  end

  private

  def remove_bookmarks
    Bookmark.between(blocker, blocked).destroy_all
    JournalBookmark.between(blocker, blocked).destroy_all
  end

  def remove_coauthorships
    Coauthorship.between(blocker, blocked).destroy_all
  end

  def decline_coauthorship_invitations
    CoauthorshipInvitation.pending.between(blocker, blocked).find_each(&:declined!)
  end
end
