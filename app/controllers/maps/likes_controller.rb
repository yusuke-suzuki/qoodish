module Maps
  class LikesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!, only: %i[create destroy]

    def index
      map =
        current_user
          .referenceable_maps
          .find_by!(id: params[:map_id])

      @likes = map.votes
    end

    def create
      @map =
        current_user
          .referenceable_maps
          .includes(:user, reviews: :images)
          .find_by!(id: params[:map_id])

      current_user.liked!(@map)
    end

    def destroy
      @map =
        current_user
          .referenceable_maps
          .includes(:user, reviews: :images)
          .find_by!(id: params[:map_id])

      current_user.unliked!(@map)
    end
  end
end
