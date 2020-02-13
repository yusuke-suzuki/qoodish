class SpotsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:popular]
      @spots =
        Rails.cache.fetch('popular_spots', expires_in: 5.minutes) do
          Review
            .public_open
            .group_by(&:place_id_val)
            .sort_by { |_key, value| value.size }
            .reverse
            .take(10)
            .map { |_key, value| value[0].spot }
        end
    end
  end

  def show
    @spot = Spot.new(params[:id])
  end
end
