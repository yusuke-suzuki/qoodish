module Reviews
  module Comments
    class LikesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_sign_in!, only: %i[create destroy]

      def index
        review =
          current_user
          .referenceable_reviews
          .find_by!(id: params[:review_id])

        comment = review.comments.find_by!(id: params[:comment_id])
        @likes = comment.votes
      end

      def create
        @review =
          current_user
          .referenceable_reviews
          .includes(:map, :user, :comments)
          .find_by!(id: params[:review_id])

        comment = @review.comments.find_by!(id: params[:comment_id])

        current_user.liked!(comment)
      end

      def destroy
        @review =
          current_user
          .referenceable_reviews
          .includes(:map, :user, :comments)
          .find_by!(id: params[:review_id])

        comment = @review.comments.find_by!(id: params[:comment_id])
        current_user.unliked!(comment)
      end
    end
  end
end
