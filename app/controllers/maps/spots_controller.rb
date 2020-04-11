module Maps
  class SpotsController < ApplicationController
    before_action :authenticate_user!

    def index
      map =
        current_user
        .referenceable_maps
        .find_by!(id: params[:map_id])
      @spots = map.spots.with_deps
    end

    def show
      @spot = Spot.new(params[:id])
    end
  end
end
