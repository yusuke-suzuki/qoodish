class UserPreference < ApplicationRecord
  # A key absent from a stored snapshot falls back to its default, so a
  # notification introduced later reaches users without waiting for them
  # to revisit the settings screen.
  WEB_PUSH_DEFAULTS = {
    'coauthor_invited' => true,
    'liked' => true,
    'comment' => true,
    'published' => true
  }.freeze

  # Rows are never updated: each save appends a full snapshot of the
  # user's choices, and the latest row is the current state.
  #
  # optional with a user_id presence validation: the default belongs_to
  # validation reads the association, and Bullet then flags the owner
  # as a potential N+1 for the rest of the request. NOT NULL and the
  # foreign key keep presence enforced in the database.
  belongs_to :user, inverse_of: :preferences, optional: true

  validates :user_id, presence: true
  validate :web_push_must_hold_booleans

  def self.effective_web_push(stored)
    WEB_PUSH_DEFAULTS.merge(
      stored.to_h.slice(*WEB_PUSH_DEFAULTS.keys)
    )
  end

  private

  def web_push_must_hold_booleans
    return if web_push.is_a?(Hash) &&
              web_push.values.all? { |value| [true, false].include?(value) }

    errors.add(:web_push, :invalid)
  end
end
