class Guest::ChaptersController < ApplicationController
  def index
    @chapters = Chapter
                .public_open
                .latest_feed
                .preload(:map, user: %i[images journal])
  end

  def show
    @chapter = Chapter
               .public_open
               .preload(:map, user: %i[images journal])
               .find_by!(id: params[:id])
  end
end
