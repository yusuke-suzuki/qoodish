module V2
  module Guest
    class ChaptersController < ApplicationController
      def index
        @chapters = Chapter
                    .public_open
                    .feed_page(params[:cursor])
                    .preload(:map, :images, :votes, user: %i[image journal])
        @next_cursor = FeedCursor.next_token(@chapters, CHAPTER_FEED_PER_PAGE)
      end
    end
  end
end
