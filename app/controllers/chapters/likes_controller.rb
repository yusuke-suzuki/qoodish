module Chapters
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def create
      @chapter = Chapter
                 .referenceable_by(current_user)
                 .find_by!(id: params[:chapter_id])

      current_user.liked!(@chapter)
    end

    def destroy
      @chapter = Chapter
                 .referenceable_by(current_user)
                 .find_by!(id: params[:chapter_id])

      current_user.unliked!(@chapter)
    end
  end
end
