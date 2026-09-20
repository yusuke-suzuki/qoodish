class ChaptersController < ApplicationController
  before_action :authenticate_user!

  def index
    @chapters = if params[:next_timestamp]
                  Chapter
                    .feed_for(current_user)
                    .feed_before(params[:next_timestamp], params[:next_id])
                    .preload(:map, :votes, :images, user: %i[image journal])
                else
                  Chapter
                    .feed_for(current_user)
                    .latest_feed
                    .preload(:map, :votes, :images, user: %i[image journal])
                end
  end

  def show
    @chapter = Chapter
               .readable_by(current_user)
               .preload(:map, :votes, user: %i[image journal])
               .find_by!(id: params[:id])
  end
end
