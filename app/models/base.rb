class Base
  def initialize(place_id_val)
    @place_id_val = place_id_val
    load_place_detail
  end

  def load_place_detail
    @place_detail = PlaceDetail.find_or_create_by!(
      place_id_val: @place_id_val,
      locale: I18n.locale
    )
  end

  def place_id
    @place_detail.place_id_val
  end

  def name
    @place_detail.name
  end

  def lat
    @place_detail.latitude.to_f
  end

  def lng
    @place_detail.longitude.to_f
  end

  def lost
    @place_detail.lost
  end
end
