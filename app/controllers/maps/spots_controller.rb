module Maps
  class SpotsController < ApplicationController
    before_action :authenticate_user!

    def index
      map =
        current_user
          .referenceable_maps
          .find_by!(id: params[:map_id])
      @spots = map.spots.includes(:images, reviews: [:map, :user, :images, comments: [:user, :votes, :voters]])
    end

    def show
      map =
        current_user
          .referenceable_maps
          .find_by!(id: params[:map_id])
      @spot = map.spots.find_by!(place_id_val: params[:id])
    end
  end
end
