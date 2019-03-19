module Reviews
  class CommentsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: %i[create destroy]

    def create
      @review =
        current_user
        .referenceable_reviews
        .includes(:map, :user, :comments)
        .find_by!(id: params[:review_id])

      ActiveRecord::Base.transaction do
        @review.comments.create!(
          user: current_user,
          body: params[:comment]
        )
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        @review =
          current_user
          .referenceable_reviews
          .includes(:map, :user, :comments)
          .find_by!(id: params[:review_id])

        comment = current_user.comments.find_by!(id: params[:id], review: @review)
        comment.destroy!
      end
    end
  end
end
