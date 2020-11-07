module PlaceStore
  extend ActiveSupport::Concern

  attr_accessor :name,
                :lat,
                :lng,
                :formatted_address,
                :url,
                :opening_hours,
                :lost

  def place_id
    @place_id_val || place_id_val
  end

  private

  def load_cache
    Rails.logger.debug("Loading cache of place: #{place_id}")
    cache = Redis::HashKey.new("#{place_id}:#{I18n.locale}", expiration: 1.month)

    if cache.blank?
      cache = store_cache
    end

    @name = extract_place_name(cache)
    @lat = cache[:lat]
    @lng = cache[:lng]
    @formatted_address = cache[:formatted_address]
    @url = cache[:url]
    @opening_hours = cache[:opening_hours]
  rescue Redis::CannotConnectError => e
    Rails.logger.error(e)
    place = fetch_place
    @name = place.name
    @lat = place.lat
    @lng = place.lng
    @formatted_address = place.formatted_address
    @url = place.url
    @opening_hours = place.opening_hours.to_json
  rescue GooglePlaces::NotFoundError => e
    Rails.logger.error("Place not found on google. place_id: #{place_id}")
    Rails.logger.error(e)
    self.lost = true
  end

  def store_cache
    Rails.logger.debug("Storing new cache of place: #{place_id}")
    place = fetch_place
    cache = Redis::HashKey.new("#{place_id}:#{I18n.locale}", expiration: 1.month)

    cache.bulk_set(
      place_id: place.place_id,
      name: place.name,
      lat: place.lat,
      lng: place.lng,
      formatted_address: place.formatted_address,
      url: place.url,
      opening_hours: place.opening_hours.to_json
    )

    cache
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
    places_api.spot(place_id, language: I18n.locale)
  end

  def places_api
    @places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])
  end
end
