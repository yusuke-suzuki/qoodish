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
end
