module Reviews
  class LikesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: %i[create destroy]

    def index
      review =
        current_user
        .referenceable_reviews
        .find_by!(id: params[:review_id])

      @likes = review.votes
    end

    def create
      @review =
        current_user
        .referenceable_reviews
        .includes(:map, :user, :comments)
        .find_by!(id: params[:review_id])

      ActiveRecord::Base.transaction do
        current_user.liked!(@review)
      end
    end

    def destroy
      @review =
        current_user
        .referenceable_reviews
        .includes(:map, :user, :comments)
        .find_by!(id: params[:review_id])

      current_user.unliked!(@review)
    end
  end
end
