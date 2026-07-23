module Me
  module Bookmarks
    class MapsController < ApplicationController
      before_action :authenticate_user!

      def index
        # Bookmarks can only be created on public maps, so public_open is a
        # defensive filter rather than a functional one.
        @maps = Map
                .public_open
                .bookmarked_by(current_user)
                .preload(:images, user: :images)
                .order(created_at: :desc)
      end
    end
  end
end
