module Me
  class MutesController < ApplicationController
    before_action :authenticate_user!

    def index
      @mutes = current_user.mutes.latest_per_muted(params[:next_id]).preload(muted: :image)
    end
  end
end
