class Base
  include PlaceStore

  def initialize(place_id_val)
    @place_id_val = place_id_val
    load_cache
  end
end
