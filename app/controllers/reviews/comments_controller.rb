module Reviews
  class CommentsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: [:create, :destroy]

    def create
      @review = Review.includes(:map, :user, :comments).find_by!(id: params[:review_id])
      raise Exceptions::NotFound unless current_user.referenceable?(@review.map)

      ActiveRecord::Base.transaction do
        @review.comments.create!(
          user: current_user,
          body: params[:comment]
        )
        Notification.create!(
          notifiable: @review,
          notifier: current_user,
          recipient: @review.user,
          key: 'comment'
        )
      end

      data = {
        notification_type: 'comment_review',
        review_id: @review.id
      }
      current_user.send_message_to_topic(
        "user_#{@review.user.id}",
        "#{current_user.name} posted a comment on your report.",
        "maps/#{@review.map_id}/reports/#{@review.id}",
        @review.thumbnail_url,
        data
      )
    end

    def destroy
      ActiveRecord::Base.transaction do
        @review = Review.includes(:map).find_by!(id: params[:review_id])
        raise Exceptions::NotFound unless current_user.referenceable?(@review.map)
        comment = @review.comments.find_by!(id: params[:id], user: current_user)
        comment.destroy!
      end
    end
  end
end
