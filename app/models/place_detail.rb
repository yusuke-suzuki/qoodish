class PlaceDetail < ApplicationRecord
  validates :place_id_val,
            presence: true,
            uniqueness: {
              scope: :locale
            }
  validates :locale,
            presence: true
  validates :lat,
            presence: true
  validates :lng,
            presence: true

  before_validation :load_place_detail

  enum locale: [:en, :ja]

  def load_place_detail
    Rails.logger.debug("[PlaceDetail] Loading place details of #{place_id_val} with locale #{locale}")
    place_detail = fetch_place_detail

    Rails.logger.debug(place_detail)

    self.assign_attributes(
      name: place_detail[:name],
      lat: place_detail[:lat],
      lng: place_detail[:lng],
      formatted_address: place_detail[:formatted_address],
      url: place_detail[:url],
      opening_hours: place_detail[:opening_hours].to_json
    )
  rescue GooglePlaces::NotFoundError => e
    Rails.logger.error("Place not found on google. place_id: #{place_id_val}")
    Rails.logger.error(e)
    self.lost = true
  rescue => e
    Rails.logger.error(e)
  end

  private

  def fetch_place_detail
    Rails.logger.debug("Fetching place details of #{place_id_val} (#{locale})")
    places_api.spot(place_id_val, language: locale)
  end

  def places_api
    @places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])
  end
end
