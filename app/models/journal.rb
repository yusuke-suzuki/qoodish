class Journal < ApplicationRecord
  include Revisable

  self.revision_attributes = %i[title description]

  belongs_to :user
  belongs_to :current_revision, class_name: 'JournalRevision', optional: true
  has_many :chapters, through: :user
  has_many :bookmarks, class_name: 'JournalBookmark', dependent: :destroy
  has_many :revisions,
           -> { order(:id) },
           class_name: 'JournalRevision',
           dependent: :destroy,
           inverse_of: :journal

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
end
