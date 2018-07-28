class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!, only: [:update, :destroy]

  def index
    if params[:recent]
      @reviews = Review.recent
    elsif current_user.following_maps.length.zero?
      @reviews = []
    elsif params[:next_timestamp]
      @reviews = Review.map_posts_for(current_user).feed_before(params[:next_timestamp])
    else
      @reviews = Review.map_posts_for(current_user).latest_feed
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
