class Guest::PinsController < ApplicationController
  def show
    @pin = Pin
           .public_open
           .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])
           .find_by!(id: params[:id])
  end

  def index
    @pins = if params[:input].present?
              Pin
                .public_open
                .search(params[:input])
                .order(created_at: :desc)
                .limit(20)
                .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])
            elsif params[:feed]
              feed
            elsif params[:recent]
              Pin
                .public_open
                .limit(8)
                .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])
                .order(created_at: :desc)
            elsif params[:popular]
              Pin
                .public_open
                .popular
                .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])
            else
              raise Exceptions::BadRequest
            end
  end

  private

  def feed
    scope = Pin
            .public_open
            .preload(:map, { user: :image }, :images, :votes, comments: [{ user: :image }, :votes])

    if params[:next_timestamp]
      scope.feed_before(params[:next_timestamp], params[:next_id])
    else
      scope.latest_feed
    end
  end
end
