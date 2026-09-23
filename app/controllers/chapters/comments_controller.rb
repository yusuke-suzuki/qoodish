module Chapters
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    def index
      @comments = chapter.comments.order(:id).preload({ user: :image }, :votes)
    end

    def create
      @comment = Comment.record!(
        user: current_user,
        commentable: chapter,
        body: params[:comment]
      )
    end

    def update
      @comment = own_comment.revise!(user: current_user, body: params[:comment])
    end

    def destroy
      @comment = own_comment.discard!(user: current_user)
    end

    private

    def chapter
      @chapter ||= Chapter.readable_by(current_user).find_by!(id: params[:chapter_id])
    end

    def own_comment
      current_user.comments.find_by!(id: params[:id], commentable: chapter)
    end
  end
end
