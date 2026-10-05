module V2
  module Me
    class PinsController < ApplicationController
      before_action :authenticate_user!

      def index
        @pins = current_user
                .pins
                .published
                .visible
                .feed_page(params[:cursor])
                .preload(:map, { user: :image }, :images, :property_options, :votes)
        @next_cursor = FeedCursor.next_token(@pins, PIN_FEED_PER_PAGE)

        @comments_by_pin_id = Comment
                              .not_deleted
                              .visible
                              .where(commentable: @pins.to_a)
                              .not_blocking(current_user)
                              .not_blocked_by(current_user)
                              .not_muted_by(current_user)
                              .preload({ user: :image }, :votes)
                              .group_by(&:commentable_id)
      end
    end
  end
end
