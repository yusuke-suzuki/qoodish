class ChaptersController < ApplicationController
  before_action :authenticate_user!

  def index
    @chapters = if params[:next_timestamp]
                  Chapter
                    .feed_for(current_user)
                    .feed_before(params[:next_timestamp])
                    .preload(:map, :votes, user: %i[images journal])
                else
                  Chapter
                    .feed_for(current_user)
                    .latest_feed
                    .preload(:map, :votes, user: %i[images journal])
                end
  end

  def show
    @chapter = Chapter
               .readable_by(current_user)
               .preload(:map, :votes, user: %i[images journal])
               .find_by!(id: params[:id])
  end
end
