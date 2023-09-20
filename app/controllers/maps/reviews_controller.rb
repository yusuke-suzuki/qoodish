module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = current_user
                 .referenceable_reviews
                 .where(map_id: params[:map_id])
                 .with_deps
                 .order(created_at: :desc)
    end

    def show
      @review =
        current_user
        .referenceable_reviews
        .with_deps
        .find_by!(id: params[:id])
    end

    def create
      map =
        current_user
        .postable_maps
        .find_by!(id: params[:map_id])

      ActiveRecord::Base.transaction do
        @review = current_user.reviews.create!(
          map: map,
          place_id_val: params[:place_id],
          comment: params[:comment]
        )

        if params[:images].present?
          params[:images].each do |image|
            @review.images.create!(
              url: image[:url]
            )
          end
        end
      end
    end
  end
end
