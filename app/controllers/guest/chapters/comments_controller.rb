module Guest
  module Chapters
    class CommentsController < ApplicationController
      def index
        chapter = Chapter.public_open.find_by!(id: params[:chapter_id])

        @comments = chapter.comments.order(:id).preload({ user: :image }, :votes)
      end
    end
  end
end
