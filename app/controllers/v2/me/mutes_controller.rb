module V2
  module Me
    class MutesController < ApplicationController
      before_action :authenticate_user!

      def index
        @mutes = current_user.mutes.latest_per_muted(params[:cursor].presence&.to_i).preload(muted: :image)
        @next_cursor = Mute.next_cursor(@mutes)
      end
    end
  end
end
