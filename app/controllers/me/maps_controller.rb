module Me
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps = current_user
              .maps
              .preload(:images, user: :images)
              .order(created_at: :desc)
    end
  end
end
