module V2
  module Guest
    class PinsController < ApplicationController
      def index
        @pins = Pin
                .public_open
                .feed_page(params[:cursor])
                .preload(:map, { user: :image }, :images, :property_options, :votes, comments: [{ user: :image }, :votes])
        @next_cursor = FeedCursor.next_token(@pins, PIN_FEED_PER_PAGE)
      end
    end
  end
end
