class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[show update destroy]

  def show
    @user = if params[:id] == current_user.uid
              current_user
            else
              User.find_by!(id: params[:id])
            end
  end

  def create
    if current_user
      @user = current_user
      return
    end

    payload = RequestContext.jwt_payload
    raise Exceptions::Unauthorized if payload.blank?

    @user = User.create!(
      uid: payload['sub'],
      name: payload['name']
    )
  end

  def update
    ActiveRecord::Associations::Preloader.new(
      records: [current_user],
      associations: [:images]
    ).call

    current_user.update!(user_params)
    @user = current_user
  end

  def destroy
    current_user.reviews.preload(:images, :votes).load
    current_user.maps.preload(:images, :invites, :follows, :votes, reviews: [:images, :votes]).load
    current_user.destroy!
  end

  private

  def user_params
    attrs = params.permit(:name, :biography, image_ids: []).to_h
    attrs['image_ids'] ||= legacy_image_ids_from_path
    attrs
  end

  # Phase 1 backward compatibility: convert legacy `image_path` (URL) into
  # an `image_ids` array. Remove together with the legacy column in Phase 3.
  def legacy_image_ids_from_path
    return unless params.key?(:image_path)

    url = params.permit(:image_path)[:image_path]
    return [] if url.blank?

    # Find globally to avoid colliding with Image's global url uniqueness when
    # the URL already belongs to another user; silently drop foreign-owned URLs.
    image = Image.find_or_create_by!(url: url) { |img| img.user_id = current_user.id }
    return [] if image.user_id != current_user.id

    [image.id]
  end
end
