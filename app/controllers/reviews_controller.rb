class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!, only: %i[update destroy]

  def index
    @reviews =
      if params[:recent]
        Rails.cache.fetch('recent_reviews', expires_in: 5.minutes) do
          Review
            .public_open
            .limit(8)
            .with_deps
            .order(created_at: :desc)
        end
      elsif params[:next_timestamp]
        Review
          .following_by(current_user)
          .feed_before(params[:next_timestamp])
          .with_deps
      elsif current_user.is_anonymous
        Rails.cache.fetch('popular_reviews', expires_in: 5.minutes) do
          Review
            .public_open
            .includes(:map, :user)
            .popular
        end
      else
        Review
          .following_by(current_user)
          .latest_feed
          .with_deps
      end
  end

  def update
    @review = current_user.reviews.with_deps.find_by!(id: params[:id])

    ActiveRecord::Base.transaction do
      @review.update!(attributes_for_update)

      if params[:images].blank?
        @review.images.destroy_all
      else
        current_image_urls = @review.images.pluck(:url)
        next_image_urls = params[:images].map { |image| image[:url] }

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

  def attributes_for_update
    attributes = {}
    attributes[:comment] = params[:comment] if params[:comment]
    attributes[:place_id_val] = params[:place_id] if params[:place_id]
    attributes
  end
end
