class Spot < ApplicationRecord
  include PlaceStore

  belongs_to :map
  has_many :reviews, dependent: :destroy
  has_many :images, through: :reviews

  validates :place_id_val,
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

  attr_accessor :name,
                :lat,
                :lng,
                :formatted_address,
                :url,
                :opening_hours

  after_create :load_cache
  after_find :load_cache

  scope :public_open, lambda {
    joins(:map)
      .where(maps: { private: false })
  }

  scope :popular, lambda {
    select('spots.place_id_val')
      .group('spots.place_id_val')
      .order('count(spots.id) desc')
      .limit(10)
  }

  def thumbnail_url(size = '200x200')
    images.present? ? images.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end
end
