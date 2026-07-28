class Vote < ApplicationRecord
  belongs_to :votable, polymorphic: true
  belongs_to :voter, polymorphic: true

  validates :votable_type,
            inclusion: {
              in: [Review.name, Map.name, Comment.name, Chapter.name]
            }
  validates :voter_type,
            inclusion: {
              in: [User.name]
            }

  after_create :create_notification, unless: :on_yourself?

  private

  def on_yourself?
    voter_id == votable.user_id
  end

  def create_notification
    return if votable.notifications.exists?(notifier: voter, key: 'liked')

    Notification.create!(
      notifiable: votable,
      notifier: voter,
      recipient: votable.user,
      key: 'liked'
    )
  end
end
