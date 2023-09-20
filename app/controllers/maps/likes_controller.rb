module Maps
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      map =
        current_user
        .referenceable_maps
        .find_by!(id: params[:map_id])

      @likes = map.votes.uniq { |vote| vote.voter.id }
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
