module Reviews
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(review.map)
      @likes = review.get_likes
    end

    def create
      @review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
      @review.liked_by(current_user)
    end

    def destroy
      @review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
      @review.unliked_by(current_user)
    end
  end
end
