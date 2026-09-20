module Me
  class MapsController < ApplicationController
    before_action :authenticate_user!

    def index
      @maps = current_user
              .maps
              .published
              .preload(:images, user: :image)
              .order(created_at: :desc)
    end
  end
end
