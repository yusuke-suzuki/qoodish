module Users
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      user = User.find_by!(id: params[:user_id])

      pins = user
             .pins
             .preload(:map, { user: :image }, :images, :votes)
             .referenceable_by(current_user)

      @pins = if params[:next_timestamp]
                pins.feed_before(params[:next_timestamp], params[:next_id])
              else
                pins.latest_feed
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
  end
end
