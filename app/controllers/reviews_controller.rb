class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def index
    @reviews = if params[:next_timestamp]
                 Review
                   .following_by(current_user)
                   .feed_before(params[:next_timestamp])
                   .preload(:map, :user, :images, { comments: :user }, :voters, :votes)
               else
                 Review
                   .following_by(current_user)
                   .latest_feed
                   .preload(:map, :user, :images, { comments: :user }, :voters, :votes)
               end
  end

  def update
    @review = current_user.reviews
                          .preload(:map, :user, :images, { comments: :user }, :voters, :votes)
                          .find_by!(id: params[:id])

    ActiveRecord::Base.transaction do
      @review.update!(review_params)

      if images_params[:images].blank?
        @review.images.destroy_all
      else
        current_image_urls = @review.images.pluck(:url)
        next_image_urls = images_params[:images].map { |image| image[:url] }

        image_urls_will_be_deleted = current_image_urls - next_image_urls
        image_urls_to_be_created = next_image_urls - current_image_urls

        @review.images.where(url: image_urls_will_be_deleted).destroy_all
        @review.reload

        image_urls_to_be_created.each do |image_url|
          @review.images.create!(
            url: image_url
          )
        end
      end

      @review.reload
    end
  end

  def destroy
    current_user.reviews.find_by!(id: params[:id]).destroy!
  end

  private

  def review_params
    params
      .permit(:name, :comment, :latitude, :longitude)
      .to_h
  end

  def images_params
    params
      .permit(images: [:url])
      .to_h
  end
end
