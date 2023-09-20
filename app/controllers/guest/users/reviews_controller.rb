class Guest::Users::ReviewsController < ApplicationController
  def index
    @reviews =
      if params[:next_timestamp]
        Review
          .public_open
          .where(user_id: params[:user_id])
          .preload(:map, :user, :images, { spot: :place }, { comments: :user })
          .feed_before(params[:next_timestamp])
      else
        Review
          .public_open
          .where(user_id: params[:user_id])
          .preload(:map, :user, :images, { spot: :place }, { comments: :user })
          .latest_feed
      end
  end
end
