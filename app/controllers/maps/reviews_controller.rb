module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = current_user
                 .referenceable_reviews
                 .where(map_id: params[:map_id])
                 .preload(:map, :user, :images, { comments: :user }, :voters, :votes)
                 .order(created_at: :desc)
    end

    def show
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, :user, :images, { comments: :user }, :voters, :votes)
        .find_by!(id: params[:id])
    end

    def create
      map =
        current_user
        .postable_maps
        .find_by!(id: params[:map_id])

      ActiveRecord::Base.transaction do
        @review = current_user.reviews.create!(review_params)

        images_params[:images].each do |image|
          @review.images.create!(
            url: image[:url]
          )
        end
      end
    end

    private

    def review_params
      params
        .permit(:map_id, :name, :comment, :latitude, :longitude)
        .to_h
    end

    def images_params
      params
        .permit(images: [:url])
        .to_h
    end
  end
end
