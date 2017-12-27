module Reviews
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(review.map)
      @likes = review.get_likes
    end

    def create
      @review = Review.includes(:map, :user).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
      @review.liked_by(current_user)
      Notification.create!(
        notifiable: @review,
        notifier: current_user,
        recipient: @review.user,
        key: 'liked'
      )
      current_user.send_message_to_user(@review.user, "#{current_user.name} liked your report.", "maps/#{@review.map_id}/reports/#{@review.id}")
    end

    def destroy
      @review = Review.includes(:map).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
      @review.unliked_by(current_user)
    end
  end
end