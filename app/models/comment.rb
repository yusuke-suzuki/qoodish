class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  has_many :votes, as: :votable, dependent: :destroy

  validates :body,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 500
            }
  validates :user_id,
            presence: true

  after_create :create_notification

  def thumbnail_url
    commentable.thumbnail_url
  end

  private

  def create_notification
    Notification.create!(
      notifiable: commentable,
      notifier: user,
      recipient: commentable.user,
      key: 'comment'
    )
  end
end
