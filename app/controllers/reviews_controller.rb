class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def index
    @reviews = if params[:next_timestamp]
                 Review
                   .feed_for(current_user)
                   .feed_before(params[:next_timestamp])
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
               else
                 Review
                   .feed_for(current_user)
                   .latest_feed
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
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
