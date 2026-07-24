class Journal < ApplicationRecord
  belongs_to :user
  has_many :chapters, through: :user
  has_many :bookmarks, class_name: 'JournalBookmark', dependent: :destroy

  validates :title,
            presence: {
              message: I18n.t('messages.api.journal_title_required')
            },
            length: {
              allow_blank: false,
              maximum: 50,
              message: I18n.t('messages.api.journal_title_exceed')
            }
  validates :description,
            length: {
              allow_blank: true,
              maximum: 200,
              message: I18n.t('messages.api.journal_description_exceed')
            }
  validates :user_id,
            presence: true,
            uniqueness: true

  scope :bookmarked_by, lambda { |user|
    where(id: JournalBookmark.where(user_id: user.id).select(:journal_id))
  }

  def bookmarked_by?(user)
    bookmarks.any? { |bookmark| bookmark.user_id == user.id }
  end

  # A journal has no images of its own; its visual identity is the author's
  # avatar, which notifications render polymorphically via the notifiable.
  def image_url
    user.image_url
  end

  def image_variants
    user.image_variants
  end
end
