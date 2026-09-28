class Bookmark < ApplicationRecord
  belongs_to :map
  belongs_to :user

  validates :user_id,
            uniqueness: {
              scope: :map_id,
              message: I18n.t('messages.api.duplicate_bookmark')
            }
  validate :map_must_be_public
  validate :user_cannot_bookmark_editable_map
  validates :user_id,
            exclusion: {
              in: ->(bookmark) { bookmark.map ? bookmark.map.user.blocked_with_user_ids : [] },
              message: :blocked_interaction
            }

  scope :between, lambda { |user, other|
    where(user_id: user.id, map_id: other.maps.select(:id))
      .or(where(user_id: other.id, map_id: user.maps.select(:id)))
  }

  private

  def map_must_be_public
    return if map.blank?

    errors.add(:map_id, I18n.t('messages.api.bookmark_map_not_public')) if map.private
  end

  def user_cannot_bookmark_editable_map
    return if map.blank? || user_id.blank?
    return unless map.user_id == user_id || map.coauthorships.exists?(user_id: user_id)

    errors.add(:user_id, I18n.t('messages.api.bookmark_map_editable'))
  end
end
