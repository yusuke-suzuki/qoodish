module Me
  class ChaptersController < ApplicationController
    before_action :authenticate_user!

    def index
      @chapters = Chapter
                  .where(user: current_user)
                  .preload(:map, :votes, user: %i[images journal])
                  .order(created_at: :desc)
    end

    def show
      @chapter = current_user.chapters.find_by!(id: params[:id])
    end

    def update
      @chapter = current_user.chapters.find_by!(id: params[:id])
      @chapter.update!(chapter_params)
    end

    def destroy
      current_user.chapters.find_by!(id: params[:id]).destroy!
    end

    private

    def chapter_params
      permitted = params.permit(:title, :status)
      permitted[:content] = params[:content].permit!.to_h if params[:content].is_a?(ActionController::Parameters)
      permitted
    end
  end
end
