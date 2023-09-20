module Maps
  module Spots
    class ReviewsController < ApplicationController
      before_action :authenticate_user!

      def index
        map = current_user
              .referenceable_maps
              .find_by!(id: params[:map_id])

        place = Place.find_by(place_id_val: params[:spot_id])

        if place.blank?
          @reviews = []
          return
        end

        spot = map.spots.find_by(place: place)

        if spot.blank?
          @reviews = []
          return
        end

        @reviews = spot.reviews.preload(:map, :user, :images, { spot: :place }, { comments: :user })
      end
    end
  end
end
