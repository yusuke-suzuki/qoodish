module Chapters
  module Comments
    class LikesController < ApplicationController
      before_action :authenticate_user!

      def create
        current_user.liked!(comment)
      end

      def destroy
        current_user.unliked!(comment)
      end

      private

      def comment
        @comment ||= chapter
                     .comments
                     .not_blocking(current_user)
                     .not_blocked_by(current_user)
                     .preload(user: :image)
                     .find_by!(id: params[:comment_id])
      end

      def chapter
        Chapter.readable_by(current_user).find_by!(id: params[:chapter_id])
      end
    end
  end
end
