class Guest::Maps::ReviewsController < ApplicationController
  def index
    @reviews = Review
               .public_open
               .preload(:map, :user, :images, { spot: :place }, { comments: :user })
               .where(map_id: params[:map_id])
               .order(created_at: :desc)
  end
end
