class Base
  include PlaceStore

  attr_accessor :name,
                :lat,
                :lng,
                :formatted_address,
                :url,
                :opening_hours,
                :lost

  def initialize(place_id_val)
    @place_id_val = place_id_val
    load_place
  end
end
