class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots =
        Rails.cache.fetch("popular_spots_#{I18n.locale}", expires_in: 5.minutes) do
          Review
            .public_open
            .group_by(&:place_id_val)
            .sort_by { |_key, value| value.size }
            .reverse
            .take(10)
            .map { |_key, value| Place.new(value[0].place_id_val) }
        end
    end
  end

  def show
    @spot = Place.new(params[:id])
  end
end
