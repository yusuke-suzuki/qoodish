module V2
  module Me
    class BlocksController < ApplicationController
      before_action :authenticate_user!

      def index
        @blocks = current_user.blocks.latest_per_blocked(params[:cursor].presence&.to_i).preload(blocked: :image)
        @next_cursor = Block.next_cursor(@blocks)
      end
    end
  end
end
