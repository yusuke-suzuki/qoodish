module Me
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = if params[:next_timestamp]
                   current_user
                     .reviews
                     .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
                     .feed_before(params[:next_timestamp])
                 else
                   current_user
                     .reviews
                     .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
                     .latest_feed
                 end
    end

    def update
      @review = current_user.reviews.find_by!(id: params[:id])
      @review.update!(review_params)

      ActiveRecord::Associations::Preloader.new(
        records: [@review],
        associations: [:map, :images, { comments: { user: :images } }, :voters, :votes]
      ).call
    end

    def destroy
      current_user.reviews.find_by!(id: params[:id]).destroy!
    end

    private

    def review_params
      params.permit(:name, :comment, :latitude, :longitude, image_ids: [])
    end
  end
end
