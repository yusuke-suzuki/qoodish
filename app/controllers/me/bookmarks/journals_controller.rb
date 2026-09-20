module Me
  module Bookmarks
    class JournalsController < ApplicationController
      before_action :authenticate_user!

      def index
        @journals = Journal
                    .bookmarked_by(current_user)
                    .preload(:bookmarks, user: :image)
                    .order(created_at: :desc)
      end
    end
  end
end
