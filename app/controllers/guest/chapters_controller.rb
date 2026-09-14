class Guest::ChaptersController < ApplicationController
  def index
    @chapters = if params[:next_timestamp]
                  Chapter
                    .public_open
                    .feed_before(params[:next_timestamp], params[:next_id])
                    .preload(:map, :images, user: %i[images journal])
                else
                  Chapter
                    .public_open
                    .latest_feed
                    .preload(:map, :images, user: %i[images journal])
                end
  end

  def show
    @chapter = Chapter
               .public_open
               .preload(:map, :images, user: %i[images journal])
               .find_by!(id: params[:id])
  end
end
