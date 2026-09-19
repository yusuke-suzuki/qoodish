module Me
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      @pins = if params[:next_timestamp]
                current_user
                  .pins
                  .published
                  .preloaded_with_votes
                  .feed_before(params[:next_timestamp], params[:next_id])
              else
                current_user
                  .pins
                  .published
                  .preloaded_with_votes
                  .latest_feed
              end
    end

    def update
      @pin = current_user.pins.published.find_by!(id: params[:id])
      @pin.revise!(user: current_user, **pin_params)

      ActiveRecord::Associations::Preloader.new(
        records: [@pin],
        associations: [:map, :images, { comments: { user: :images } }, :voters, :votes]
      ).call
    end

    def destroy
      current_user.pins.published.find_by!(id: params[:id]).delete!(user: current_user)
    end

    private

    def pin_params
      params
        .permit(:name, :comment, :latitude, :longitude, image_ids: [])
        .to_h
        .symbolize_keys
    end
  end
end
