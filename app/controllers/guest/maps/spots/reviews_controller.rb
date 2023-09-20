class Guest::Maps::Spots::ReviewsController < ApplicationController
  def index
    @reviews = Review
               .public_open
               .preload(:map, :user, :images, { spot: :place }, { comments: :user })
               .where(spot_id: params[:spot_id])
               .order(created_at: :desc)
  end
end
