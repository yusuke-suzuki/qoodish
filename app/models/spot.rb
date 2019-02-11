class Spot
  attr_accessor :place_id, :name, :lat, :lng, :formatted_address, :url, :opening_hours, :image_url

  def initialize(place_id, image_url = nil)
    @place_id = place_id
    detail = place_id.present? ? spot_detail : {}
    @name = extract_place_name(detail)
    @lat = detail[:lat]
    @lng = detail[:lng]
    @formatted_address = detail[:formatted_address]
    @url = detail[:url]
    @opening_hours = detail[:opening_hours]
    @image_url = image_url
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

  def spot_detail
    cache_place if cached_spot.blank?
    cached_spot
  rescue Redis::CannotConnectError
    fetch_place
  rescue GooglePlaces::NotFoundError => e
    Rails.logger.error("Place not found on google. place_id: #{@place_id}")
    Rails.logger.error(e)
    {}
  end

  def cache_place
    place = fetch_place
    cached_spot.bulk_set(
      place_id: place.place_id,
      name: place.name,
      lat: place.lat,
      lng: place.lng,
      formatted_address: place.formatted_address,
      url: place.url,
      opening_hours: place.opening_hours.to_json
    )
    cached_spot
  end

  def cached_spot
    Redis::HashKey.new("#{@place_id}:#{I18n.locale}", expiration: 1.month)
  end

  def fetch_place
    places_api.spot(@place_id, language: I18n.locale)
  end

  private

  def places_api
    @places_api = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY_SERVER'])
  end
end
