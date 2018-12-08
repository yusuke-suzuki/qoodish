class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :body,
            presence: true,
            length: {
              allow_blank: false,
              maximum: 500
            }
  validates :user_id,
            presence: true
end
