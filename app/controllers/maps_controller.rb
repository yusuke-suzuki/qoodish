class MapsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!, only: %i[create update destroy]

  def index
    @maps = if params[:input].present?
        current_user
          .referenceable_maps
          .search_by_words(params[:input].strip.split(/[[:blank:]]+/))
          .limit(20)
          .with_deps
          .order(created_at: :desc)
      elsif params[:recommend]
        Map
          .public_open
          .unfollowing_by(current_user)
          .with_deps
          .order(created_at: :desc)
          .sample(10)
      elsif params[:recent]
        Map
          .public_open
          .with_deps
          .order(created_at: :desc)
          .limit(12)
      elsif params[:active]
        Map
          .public_open
          .with_deps
          .active
      elsif params[:popular]
        Map
          .public_open
          .with_deps
          .popular
      elsif params[:postable]
        current_user.postable_maps.with_deps
      else
        current_user
          .following_maps
          .with_deps
          .order(created_at: :desc)
      end
  end

  def show
    @map =
      current_user
        .referenceable_maps
        .with_deps
        .find_by!(id: params[:id])
  end

  def create
    @map = current_user.maps.create!(
      name: params[:name],
      description: params[:description],
      private: params[:private],
      invitable: params[:invitable],
      shared: params[:shared],
      base_id_val: params[:base_id],
      base_name: params[:base_name],
      image_url: params[:image_url]
    )
  end

  def update
    @map = current_user.maps.includes([:votes, :voters]).find_by!(id: params[:id])
    @map.update!(attributes_for_update) if attributes_for_update.present?
  end

  def destroy
    current_user.maps.find_by!(id: params[:id]).destroy!
  end

  private

  def attributes_for_update
    attributes = {}
    attributes[:name] = params[:name] if params[:name]
    attributes[:description] = params[:description] if params[:description]
    attributes[:private] = params[:private] unless params[:private].nil?
    attributes[:base_id_val] = params[:base_id] if params[:base_id]
    attributes[:base_name] = params[:base_name] if params[:base_name]
    attributes[:invitable] = params[:invitable] unless params[:invitable].nil?
    attributes[:shared] = params[:shared] unless params[:shared].nil?
    attributes[:image_url] = params[:image_url] if params[:image_url].present?
    attributes
  end
end
