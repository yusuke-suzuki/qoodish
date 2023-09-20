class Guest::Maps::SpotsController < ApplicationController
  def index
    @spots = Spot
             .public_open
             .preload(:place, :images, reviews: [:images])
             .where(map_id: params[:map_id])
             .order(created_at: :desc)
  end

  def show
    @spot = Spot
            .public_open
            .preload(:place, :images, reviews: [:images])
            .find_by!(id: params[:id])
  end
end
