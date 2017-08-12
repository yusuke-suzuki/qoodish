module Maps
  class SpotsController < ApplicationController
    before_action :authenticate_user!

    def index
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @spots = map.spots
    end

    def show
      map = Map.find_by!(id: params[:map_id], base_id_val: params[:id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @spot = Spot.new(params[:id])
    end
  end
end
