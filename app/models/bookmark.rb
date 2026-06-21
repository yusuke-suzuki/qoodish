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
