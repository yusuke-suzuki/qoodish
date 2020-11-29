class Place < ApplicationRecord
  include PlaceStore

  has_many :spots, dependent: :destroy
  has_many :reviews, through: :spots

  validates :place_id_val,
            presence: true,
            uniqueness: true
  validates :name,
            presence: true
  validates :lat,
            presence: true
  validates :lng,
            presence: true

  before_validation :load_place

  scope :popular, lambda {
    joins(:reviews)
      .group('places.id')
      .order('count(reviews.id) desc')
      .limit(10)
  }

  def thumbnail_url(size = '200x200')
    reviews.public_open.exists? ? reviews.public_open.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end
end
