module Reviews
  module Comments
    class LikesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_sign_in!, only: [:create, :destroy]

      def create
        @review = Review.includes(:map, :user, :comments).find_by!(id: params[:review_id])
        raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
        comment = @review.comments.find(params[:comment_id])

        ActiveRecord::Base.transaction do
          comment.liked_by(current_user)
          Notification.create!(
            notifiable: comment,
            notifier: current_user,
            recipient: comment.user,
            key: 'liked'
          )
        end

        data = {
          notification_type: 'like_comment',
          review_id: @review.id
        }
        current_user.send_message_to_topic(
          "user_#{comment.user.id}",
          "#{current_user.name} liked your comment.",
          "maps/#{@review.map_id}/reports/#{@review.id}",
          @review.thumbnail_url,
          data
        )
      end

      def destroy
        @review = Review.includes(:map).find_by!(id: params[:review_id])
        raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
        comment = @review.comments.find(params[:comment_id])
        comment.unliked_by(current_user)
      end
    end
  end
end
