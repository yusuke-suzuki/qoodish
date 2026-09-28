module Chapters
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    def index
      @comments = chapter
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .order(:id)
                  .preload({ user: :image }, :votes)
    end

    def create
      @comment = Comment.record!(
        user: current_user,
        commentable: chapter,
        body: params[:comment]
      )
    end

    def update
      comment = current_user.comments.find_by!(id: params[:id], commentable: chapter)
      @comment = comment.revise!(user: current_user, body: params[:comment])
    end

    def destroy
      comment = current_user.comments.find_by!(id: params[:id], commentable: chapter)
      @comment = comment.discard!(user: current_user)
    end

    private

    def chapter
      @chapter ||= Chapter.readable_by(current_user).find_by!(id: params[:chapter_id])
    end
  end
end
