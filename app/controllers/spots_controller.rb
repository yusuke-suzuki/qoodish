class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots =
        Rails.cache.fetch("popular_spots_#{I18n.locale}", expires_in: 5.minutes) do
          Place.popular
        end
    end
  end

  def show
    @spot = Place.new(params[:id])
  end
end
