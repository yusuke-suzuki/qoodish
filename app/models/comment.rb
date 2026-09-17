# frozen_string_literal: true

class Comment < ApplicationRecord
  include Revisable
  include RevisableStatus
  include Moderatable

  self.revision_attributes = %i[body]

  belongs_to :commentable, polymorphic: true
  belongs_to :user
  belongs_to :current_revision, class_name: 'CommentRevision', optional: true
  has_many :revisions,
           -> { order(:id) },
           class_name: 'CommentRevision',
           dependent: :destroy,
           inverse_of: :comment
  has_many :votes, as: :votable, dependent: :destroy
  has_many :voters, through: :votes, source: :voter, source_type: User.name
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  normalizes :body, with: ->(text) { text.delete("\r") }

  validates :body,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 500
            }
  validates :user_id,
            presence: true

  after_create :create_notification, unless: :on_yourself?

  def image_url
    commentable.image_url
  end

  def image_variants
    commentable.image_variants
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
