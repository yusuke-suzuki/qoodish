class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots =
        Rails.cache.fetch("popular_spots_#{I18n.locale}", expires_in: 5.minutes) do
          Spot.public_open.popular.map { |spot| Place.new(spot.place_id_val) }
        end
    end
  end

  def show
    @spot = Place.new(params[:id])
  end
end
