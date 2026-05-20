module Maps
  class ReviewsController < ApplicationController
    before_action :authenticate_user!

    def index
      @reviews = current_user
                 .referenceable_reviews
                 .where(map_id: params[:map_id])
                 .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
                 .order(created_at: :desc)
    end

    def show
      @review =
        current_user
        .referenceable_reviews
        .preload(:map, { user: :images }, :images, { comments: { user: :images } }, :voters, :votes)
        .find_by!(id: params[:id])
    end

    def create
      current_user
        .postable_maps
        .find_by!(id: params[:map_id])

      @review = current_user.reviews.create!(review_params)
    end

    private

    def review_params
      attrs = params.permit(:map_id, :name, :comment, :latitude, :longitude, image_ids: []).to_h
      attrs['image_ids'] ||= legacy_image_ids_from_images
      attrs
    end

    # Phase 1 backward compatibility: convert legacy `images: [{url: "..."}]`
    # into an `image_ids` array. Remove together with the legacy schema in Phase 3.
    def legacy_image_ids_from_images
      return unless params.key?(:images)
      return [] if params[:images].blank?

      params.permit(images: [:url]).fetch(:images, []).filter_map do |image|
        url = image[:url]
        next if url.blank?

        # Find globally to avoid colliding with Image's global url uniqueness
        # when the URL already belongs to another user; drop foreign-owned URLs.
        record = Image.find_or_create_by!(url: url) { |img| img.user_id = current_user.id }
        next if record.user_id != current_user.id

        record.id
      end
    end
  end
end
