module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = current_user
                 .referenceable_reviews
                 .where(map_id: params[:map_id])
                 .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
                 .order(created_at: :desc)
    end

    def show
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
        .find_by!(id: params[:id])
    end

    def create
      current_user
        .postable_maps
        .find_by!(id: params[:map_id])

      @review = current_user.reviews.create!(review_params)
    end

    private

    def review_params
      params.permit(:map_id, :name, :comment, :latitude, :longitude, image_ids: [])
    end
  end
end
