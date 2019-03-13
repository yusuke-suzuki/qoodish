module Reviews
  class LikesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: %i[create destroy]

    def index
      review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(review.map)

      @likes = review.get_likes
    end

    def create
      @review = Review.includes(:map, :user, :comments).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)

      ActiveRecord::Base.transaction do
        @review.liked_by(current_user)
        Notification.create!(
          notifiable: @review,
          notifier: current_user,
          recipient: @review.user,
          key: 'liked'
        )
      end
    end

    def destroy
      @review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)

      @review.unliked_by(current_user)
    end
  end
end
