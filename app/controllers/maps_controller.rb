class MapsController < ApplicationController
  before_action :authenticate_user!

  def index
    @maps = if params[:recommend]
              Map
                .public_open
                .unfollowing_by(current_user)
                .preload(:images, user: :images)
                .order(created_at: :desc)
                .sample(10)
            else
              current_user
                .following_maps
                .preload(:images, user: :images)
                .order(created_at: :desc)
            end
  end

  def show
    @map =
      current_user
      .referenceable_maps
      .preload(:images, user: :images)
      .find_by!(id: params[:id])
  end

  def create
    @map = current_user.maps.create!(map_params)

    ActiveRecord::Associations::Preloader.new(
      records: [@map],
      associations: :images
    ).call
  end

  def update
    @map = current_user.maps.find_by!(id: params[:id])
    @map.update!(map_params)

    ActiveRecord::Associations::Preloader.new(
      records: [@map],
      associations: :images
    ).call
  end

  def destroy
    current_user.maps.find_by!(id: params[:id]).destroy!
  end

  private

  def map_params
    attrs = params.permit(:name, :description, :private, :invitable, :shared, :latitude, :longitude, image_ids: []).to_h
    attrs['image_ids'] ||= legacy_image_ids_from_url
    attrs
  end

  # Phase 1 backward compatibility: convert legacy `image_url` (URL) into
  # an `image_ids` array. Remove together with the legacy column in Phase 3.
  def legacy_image_ids_from_url
    return unless params.key?(:image_url)

    url = params.permit(:image_url)[:image_url]
    return [] if url.blank?

    # Find globally to avoid colliding with Image's global url uniqueness when
    # the URL already belongs to another user; silently drop foreign-owned URLs.
    image = Image.find_or_create_by!(url: url) { |img| img.user_id = current_user.id }
    return [] if image.user_id != current_user.id

    [image.id]
  end
end
