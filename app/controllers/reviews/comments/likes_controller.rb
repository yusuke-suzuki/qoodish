module Reviews
  module Comments
    class LikesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_sign_in!, only: %i[create destroy]

      def index
        comment = Comment.find_by!(id: params[:comment_id])
        raise Exceptions::NotFound unless current_user.referenceable?(comment.commentable.map)

        @likes = comment.get_likes
      end

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
