class Guest::Users::BookmarksController < ApplicationController
  def index
    # Bookmarks can only be created on public maps, so public_open is a
    # defensive filter rather than a functional one.
    @maps = Map
            .public_open
            .where(id: Bookmark.where(user_id: params[:user_id]).select(:map_id))
            .preload(:images, user: :images)
            .order(created_at: :desc)
  end
end
