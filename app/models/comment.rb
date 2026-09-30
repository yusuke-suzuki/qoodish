# frozen_string_literal: true

class Comment < ApplicationRecord
  include Revisable
  include RevisableStatus
  include Moderatable
  include Votable
  include Blockable
  include Mutable

  self.revision_attributes = %i[body]

  belongs_to :commentable, polymorphic: true
  belongs_to :user
  belongs_to :current_revision, class_name: 'CommentRevision', optional: true
  has_many :revisions,
           -> { order(:id) },
           class_name: 'CommentRevision',
           dependent: :destroy,
           inverse_of: :comment
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
  validates :user_id,
            exclusion: {
              in: ->(comment) { comment.commentable ? comment.commentable.user.blocked_with_user_ids : [] },
              message: :blocked_interaction
            },
            on: :create

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
