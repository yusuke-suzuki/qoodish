module Me
  class PinsController < ApplicationController
    before_action :authenticate_user!

    def index
      @pins = if params[:next_timestamp]
                current_user
                  .pins
                  .published
                  .visible
                  .preload(:map, { user: :image }, :images, :property_options, :votes)
                  .feed_before(params[:next_timestamp], params[:next_id])
              else
                current_user
                  .pins
                  .published
                  .visible
                  .preload(:map, { user: :image }, :images, :property_options, :votes)
                  .latest_feed
              end

      @comments_by_pin_id = Comment
                            .not_deleted
                            .visible
                            .where(commentable: @pins.to_a)
                            .not_blocking(current_user)
                            .not_blocked_by(current_user)
                            .not_muted_by(current_user)
                            .preload({ user: :image }, :votes)
                            .group_by(&:commentable_id)
    end

    def update
      pin = current_user.pins.published.find_by!(id: params[:id])
      pin.revise!(user: current_user, **pin_params)

      @pin = current_user.pins.preload(:map, :images, :property_options, :votes).find(pin.id)
      @comments = @pin
                  .comments
                  .not_blocking(current_user)
                  .not_blocked_by(current_user)
                  .not_muted_by(current_user)
                  .preload({ user: :image }, :votes)
    end

    def destroy
      current_user.pins.published.find_by!(id: params[:id]).discard!(user: current_user)
    end

    private

    def pin_params
      params
        .permit(:name, :comment, :latitude, :longitude, image_ids: [], property_option_ids: [])
        .to_h
        .symbolize_keys
    end
  end
end
