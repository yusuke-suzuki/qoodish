class Guest::ChaptersController < ApplicationController
  def index
    if params[:input].present?
      @chapters = Chapter
                  .public_open
                  .search(params[:input])
                  .order(created_at: :desc)
                  .limit(20)
                  .preload(:map, :images)

      return render :search
    end

    @chapters = if params[:next_timestamp]
                  Chapter
                    .public_open
                    .feed_before(params[:next_timestamp], params[:next_id])
                    .preload(:map, :images, :votes, user: %i[image journal])
                else
                  Chapter
                    .public_open
                    .latest_feed
                    .preload(:map, :images, :votes, user: %i[image journal])
                end
  end

  def show
    @chapter = Chapter
               .public_open
               .preload(:map, :images, :votes, user: %i[image journal])
               .find_by!(id: params[:id])
  end
end
