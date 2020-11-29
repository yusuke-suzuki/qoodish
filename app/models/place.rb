class Place < ApplicationRecord
  has_many :spots, dependent: :destroy
  has_many :reviews, through: :spots

  validates :place_id_val,
            presence: true,
            uniqueness: true

  before_validation :load_place_detail
  after_find :load_place_detail

  scope :popular, lambda {
    joins(:reviews)
      .group('places.id')
      .order('count(reviews.id) desc')
      .limit(10)
  }

  def load_place_detail
    Rails.logger.debug("[Place] Loading place details of #{place_id_val}")

    @place_detail = PlaceDetail.find_or_create_by!(
      place_id_val: place_id_val,
      locale: I18n.locale
    )
  end

  def name
    @place_detail.name
  end

  def lat
    @place_detail.lat
  end

  def lng
    @place_detail.lng
  end

  def formatted_address
    @place_detail.formatted_address
  end

  def url
    @place_detail.url
  end

  def opening_hours
    @place_detail.opening_hours
  end

  def lost
    @place_detail.lost
  end

  def thumbnail_url(size = '200x200')
    reviews.public_open.exists? ? reviews.public_open.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end
end
