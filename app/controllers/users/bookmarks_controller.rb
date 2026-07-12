module Users
  class BookmarksController < ApplicationController
    before_action :authenticate_user!

    def index
      user = if params[:user_id] == current_user.uid
               current_user
             else
               User.find_by!(id: params[:user_id])
             end

      # Bookmarks can only be created on public maps, so public_open is a
      # defensive filter rather than a functional one.
      @maps = Map
              .public_open
              .bookmarked_by(user)
              .preload(:images, user: :images)
              .order(created_at: :desc)
    end
  end
end
