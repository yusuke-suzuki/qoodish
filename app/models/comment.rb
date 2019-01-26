class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  acts_as_votable

  validates :body,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 500
            }
  validates :user_id,
            presence: true

  def thumbnail_url
    commentable.thumbnail_url
  end
end
