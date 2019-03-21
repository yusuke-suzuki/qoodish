module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: :create

    def index
      @reviews =
        if params[:place_id].present?
          current_user
            .referenceable_reviews
            .includes(:map, :user, :comments)
            .where(place_id_val: params[:place_id])
        else
          current_user
            .referenceable_reviews
            .where(map_id: params[:map_id])
            .includes(:map, :user, :comments)
            .order(created_at: :desc)
        end
    end

    def show
      @review =
        current_user
        .referenceable_reviews
        .includes(:map, :user, :comments)
        .find_by!(id: params[:id])
    end

    def create
      ActiveRecord::Base.transaction do
        map =
          current_user
          .postable_maps
          .find_by!(id: params[:map_id])

        @review = current_user.reviews.create!(
          map: map,
          place_id_val: params[:place_id],
          comment: params[:comment],
          image_url: params[:image_url]
        )
      end
    end
  end
end
