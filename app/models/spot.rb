class Spot < ApplicationRecord
  include PlaceStore

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

  before_validation :create_place
  after_create :load_cache
  after_find :load_cache
  after_destroy :destroy_empty_place

  scope :public_open, lambda {
    joins(:map)
      .where(maps: { private: false })
  }

  def thumbnail_url(size = '200x200')
    images.present? ? images.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end

  private

  def create_place
    self.place = Place.find_or_create_by!(
      place_id_val: place_id_val
    )
  end

  def destroy_empty_place
    return if place.spots.exists?

    place.destroy!
  end
end
