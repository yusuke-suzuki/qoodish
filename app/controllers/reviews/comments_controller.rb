module Reviews
  class CommentsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: %i[create destroy]

    def create
      @review =
        current_user
          .referenceable_reviews
          .with_deps
          .find_by!(id: params[:review_id])

      @review.comments.create!(
        user: current_user,
        body: params[:comment]
      )
    end

    def destroy
      @review =
        current_user
          .referenceable_reviews
          .with_deps
          .find_by!(id: params[:review_id])

      comment =
        current_user
          .comments
          .find_by!(id: params[:id], commentable: @review)
      comment.destroy!

      @review.reload
    end
  end
end
