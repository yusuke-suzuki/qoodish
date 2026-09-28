class PinsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pins = if params[:next_timestamp]
              Pin
                .feed_for(current_user)
                .feed_before(params[:next_timestamp], params[:next_id])
                .preload(:map, { user: :image }, :images, :votes)
            else
              Pin
                .feed_for(current_user)
                .latest_feed
                .preload(:map, { user: :image }, :images, :votes)
            end

    @comments_by_pin_id = Comment
                          .not_deleted
                          .visible
                          .where(commentable: @pins.to_a)
                          .not_blocking(current_user)
                          .not_blocked_by(current_user)
                          .preload({ user: :image }, :votes)
                          .group_by(&:commentable_id)
  end

  def show
    @pin =
      current_user
      .referenceable_pins
      .preload(:map, { user: :image }, :images, :votes)
      .find_by!(id: params[:id])

    @comments = @pin
                .comments
                .not_blocking(current_user)
                .not_blocked_by(current_user)
                .preload({ user: :image }, :votes)
  end
end
