module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @reviews =
        if params[:place_id].present?
          map.reviews.includes(:user).where(place_id_val: params[:place_id])
        else
          map.reviews.includes(:user).order(created_at: :desc)
        end
    end

    def show
      map = Map.find_by!(id: params[:map_id])
      raise Exceptions::NotFound unless current_user.referenceable?(map)
      @review = map.reviews.find_by!(id: params[:id])
    end

    def create
      ActiveRecord::Base.transaction do
        map = Map.find_by!(id: params[:map_id])
        raise Exceptions::NotFound unless current_user.postable?(map)
        @review = current_user.reviews.create!(
          map: map,
          place_id_val: params[:place_id],
          comment: params[:comment],
          image_url: params[:image_url]
        )
        message = "#{current_user.name} posted a report about #{@review.spot.name} on #{map.name}."
        current_user.send_message_to_topic("map_#{map.id}", message, "maps/#{map.id}/reports/#{@review.id}")
      end
    end
  end
end
