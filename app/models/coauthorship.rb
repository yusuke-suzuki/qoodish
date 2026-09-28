class Coauthorship < ApplicationRecord
  belongs_to :map
  belongs_to :user

  validates :user_id,
            uniqueness: {
              scope: :map_id,
              message: I18n.t('messages.api.duplicate_coauthor')
            }
  validate :author_is_not_coauthor

  scope :between, lambda { |user, other|
    where(user_id: user.id, map_id: other.maps.select(:id))
      .or(where(user_id: other.id, map_id: user.maps.select(:id)))
  }

  private

  def author_is_not_coauthor
    return if map.blank? || user_id.blank?

    errors.add(:user_id, I18n.t('messages.api.coauthor_already_author')) if map.user_id == user_id
  end
end
