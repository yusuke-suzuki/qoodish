class JournalBookmark < ApplicationRecord
  belongs_to :journal
  belongs_to :user

  validates :user_id,
            uniqueness: {
              scope: :journal_id,
              message: I18n.t('messages.api.duplicate_journal_bookmark')
            }
  validate :user_cannot_bookmark_own_journal

  after_create :create_notification

  private

  def create_notification
    Notification.create!(
      notifiable: journal,
      notifier: user,
      recipient: journal.user,
      key: 'bookmarked'
    )
  end

  def user_cannot_bookmark_own_journal
    return if journal.blank? || user_id.blank?
    return unless journal.user_id == user_id

    errors.add(:user_id, I18n.t('messages.api.journal_bookmark_own'))
  end
end
