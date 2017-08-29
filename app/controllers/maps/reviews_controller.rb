module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @reviews = map.reviews.includes(:user, :map).where(place_id_val: params[:place_id])
    end

    def show
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @review = map.reviews.find_by!(id: params[:id])
    end

    def create
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.postable?(map)
      @review = current_user.reviews.create!(
        map: map,
        place_id_val: params[:place_id],
        comment: params[:comment],
        image_url: params[:image_url]
      )
    end
  end
end
