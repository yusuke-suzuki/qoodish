module Users
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      user = User.find_by!(id: params[:user_id])

      @maps = current_user
              .referenceable_maps
              .preload(:images, user: :images)
              .where(user_id: user.id)
              .order(created_at: :desc)
    end
  end
end
