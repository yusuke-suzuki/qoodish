module Reviews
  class CommentsController < ApplicationController
    before_action :authenticate_user!

    def create
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, { user: :images }, :images, { comments: { user: :images } })
        .find_by!(id: params[:review_id])

      @review.comments.create!(
        user: current_user,
        body: params[:comment]
      )

      @review.reload
    end

    def destroy
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, { user: :images }, :images, { comments: { user: :images } })
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
