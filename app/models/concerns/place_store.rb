module PlaceStore
  extend ActiveSupport::Concern

  def place_id
    @place_id_val || place_id_val
  end

  private

  def load_place
    Rails.logger.debug("Loading place details of #{place_id}")
    place = fetch_place
    Rails.logger.debug(place)

    self.name = place.name
    self.lat = place.lat
    self.lng = place.lng
    self.formatted_address = place.formatted_address
    self.url = place.url
    self.opening_hours = place.opening_hours.to_json
  rescue GooglePlaces::NotFoundError => e
    Rails.logger.error("Place not found on google. place_id: #{place_id}")
    Rails.logger.error(e)
    self.lost = true
  rescue => e
    Rails.logger.error(e)
  end

  def extract_place_name(detail)
    if detail[:name].present?
      detail[:name]
    elsif detail[:formatted_address].present?
      detail[:formatted_address].split(',')[0]
    else
      ''
    end
  end

  def fetch_place
    Rails.logger.debug("Fetching place details of #{place_id} (#{I18n.locale})")
    places_api.spot(place_id, language: I18n.locale)
  end

  def places_api
    @places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])
  end
end
