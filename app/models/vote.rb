class Vote < ApplicationRecord
  belongs_to :votable, polymorphic: true
  belongs_to :voter, polymorphic: true

  validates :votable_type,
            inclusion: {
              in: [Review.name, Map.name, Comment.name]
            }
  validates :voter_type,
            inclusion: {
              in: [User.name]
            }

  after_create :create_notification

  private

  def create_notification
    Notification.create!(
      notifiable: votable,
      notifier: voter,
      recipient: votable.user,
      key: 'liked'
    )
  end
end
