module Reviews
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      review =
        current_user
        .referenceable_reviews
        .find_by!(id: params[:review_id])

      @likes = review.votes.uniq { |vote| vote.voter.id }
    end

    def create
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, :user, :images, { comments: :user })
        .find_by!(id: params[:review_id])

      current_user.liked!(@review)

      @review.reload
    end

    def destroy
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, :user, :images, { comments: :user })
        .find_by!(id: params[:review_id])

      current_user.unliked!(@review)

      @review.reload
    end
  end
end
