class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name

  validates :body,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 500
            }
  validates :user_id,
            presence: true

  after_create :create_notification, unless: :on_yourself?

  def thumbnail_url
    commentable.thumbnail_url
  end

  def on_yourself?
    user.id == commentable.user.id
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
