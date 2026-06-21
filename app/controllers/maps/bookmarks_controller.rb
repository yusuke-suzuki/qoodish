module Maps
  class BookmarksController < ApplicationController
    before_action :authenticate_user!

    def create
      @map = Map.public_open.find_by!(id: params[:map_id])

      raise Exceptions::Forbidden unless current_user.bookmarkable?(@map)

      current_user.bookmark!(@map)

      preload_map_for_serialization
    end

    def destroy
      @map = current_user.bookmarked_maps.find_by!(id: params[:map_id])

      current_user.unbookmark!(@map)

      preload_map_for_serialization
    end

    private

    def preload_map_for_serialization
      ActiveRecord::Associations::Preloader.new(
        records: [@map],
        associations: [:images, { user: :images }]
      ).call
    end
  end
end
