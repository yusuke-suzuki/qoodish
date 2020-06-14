class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @places =
        Rails.cache.fetch("popular_spots_#{I18n.locale}", expires_in: 5.minutes) do
          Place.popular
        end
    end
  end

  def show
    @place = Place.find_by!(place_id_val: params[:id])
  end
end
