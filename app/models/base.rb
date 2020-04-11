class Base
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
end
