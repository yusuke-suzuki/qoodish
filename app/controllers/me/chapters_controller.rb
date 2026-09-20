module Me
  class ChaptersController < ApplicationController
    before_action :authenticate_user!

    def index
      @chapters = Chapter
                  .where(user: current_user)
                  .not_deleted
                  .preload(:map, :votes, :images, user: %i[images journal])
                  .order(created_at: :desc)
    end

    def show
      @chapter = current_user.chapters.not_deleted.find_by!(id: params[:id])
    end

    def update
      @chapter = current_user.chapters.not_deleted.find_by!(id: params[:id])
      @chapter.revise!(user: current_user, **chapter_params)

      ActiveRecord::Associations::Preloader.new(
        records: [@chapter],
        associations: :images
      ).call
    end

    def destroy
      current_user.chapters.not_deleted.find_by!(id: params[:id]).discard!(user: current_user)
    end

    private

    def chapter_params
      permitted = params.permit(:title, :status, image_ids: []).to_h.symbolize_keys
      permitted[:content] = params[:content].permit!.to_h if params[:content].is_a?(ActionController::Parameters)
      permitted[:map_features] = params[:map_features].permit!.to_h if params[:map_features].is_a?(ActionController::Parameters)
      permitted
    end
  end
end
