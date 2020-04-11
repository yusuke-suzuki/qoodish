class Place
  include PlaceStore

  attr_accessor :place_id_val,
                :name,
                :lat,
                :lng,
                :formatted_address,
                :url,
                :opening_hours

  def initialize(place_id)
    @place_id_val = place_id
    load_cache
  end

  def reviews
    Review.public_open.where(place_id_val: @place_id_val)
  end

  def thumbnail_url(size = '200x200')
    reviews.exists? ? reviews.first.thumbnail_url(size) : ENV['SUBSTITUTE_URL']
  end
end
