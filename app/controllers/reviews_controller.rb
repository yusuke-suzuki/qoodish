class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!, only: %i[update destroy]

  def index
    @reviews =
      if params[:recent]
        Review
          .public_open
          .limit(8)
          .includes(:user, :map, :comments)
      elsif params[:next_timestamp]
        Review
          .following_by(current_user)
          .feed_before(params[:next_timestamp])
          .includes(:user, :map, :comments)
      else
        Review
          .following_by(current_user)
          .latest_feed
          .includes(:user, :map, :comments)
      end
  end

  def update
    @review = current_user.reviews.find_by!(id: params[:id])
    @review.update!(attributes_for_update)
  end

  def destroy
    ActiveRecord::Base.transaction do
      current_user.reviews.find_by!(id: params[:id]).destroy!
    end
  end

  private

  def attributes_for_update
    attributes = {}
    attributes[:comment] = params[:comment] if params[:comment]
    attributes[:image_url] = params[:image_url] if params[:image_url]
    attributes[:place_id_val] = params[:place_id] if params[:place_id]
    attributes
  end
end
