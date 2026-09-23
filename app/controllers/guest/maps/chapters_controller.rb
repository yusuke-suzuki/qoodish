class Guest::Maps::ChaptersController < ApplicationController
  def index
    map = Map.public_open.find_by!(id: params[:map_id])

    @chapters = Chapter
                .public_open
                .where(map_id: map.id)
                .preload(:map, :images, :votes, user: %i[image journal])
                .order(created_at: :desc)
  end
end
