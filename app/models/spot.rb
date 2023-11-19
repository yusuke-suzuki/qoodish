class Spot < ApplicationRecord
  belongs_to :map
  belongs_to :place
  has_many :reviews
  has_many :images, through: :reviews

  validates :place_id,
            presence: {
              strict: Exceptions::PlaceIdNotSpecified
            },
            uniqueness: {
              scope: %i[map_id],
              strict: Exceptions::DuplicateReview
            }
  validates :map_id,
            presence: {
              strict: Exceptions::MapNotSpecified
            }

  scope :public_open, lambda {
    joins(:map)
      .where(maps: { private: false })
  }

  def thumbnail_url(size = '200x200')
    images.present? ? images.first.thumbnail_url(size) : ''
  end
end
