class Guest::ReviewsController < ApplicationController
  def show
    @review = Review
              .public_open
              .preload(:map, { user: :images }, :images, { comments: { user: :images } })
              .find_by!(id: params[:id])
  end

  def index
    @reviews = if params[:feed]
                 feed
               elsif params[:recent]
                 Review
                   .public_open
                   .limit(8)
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } })
                   .order(created_at: :desc)
               elsif params[:popular]
                 Review
                   .public_open
                   .popular
                   .preload(:map, { user: :images }, :images, { comments: { user: :images } })
               else
                 raise Exceptions::BadRequest
               end
  end

  private

  def feed
    scope = Review
            .public_open
            .preload(:map, { user: :images }, :images, { comments: { user: :images } })

    if params[:next_timestamp]
      scope.feed_before(params[:next_timestamp], params[:next_id])
    else
      scope.latest_feed
    end
  end
end
