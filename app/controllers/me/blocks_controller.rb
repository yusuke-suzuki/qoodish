module Me
  class BlocksController < ApplicationController
    before_action :authenticate_user!

    def index
      @blocks = current_user.blocks.latest_per_blocked(params[:next_id]).preload(blocked: :image)
    end
  end
end
