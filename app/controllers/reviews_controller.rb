class ReviewsController < ApplicationController
  before_action :authenticate_user!

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
    attributes
  end
end
