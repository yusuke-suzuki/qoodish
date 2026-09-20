module Me
  module Journeys
    class CheckinsController < ApplicationController
      before_action :authenticate_user!

      def create
        journey = current_user.journeys.find_by!(id: params[:journey_id])
        pin = current_user.referenceable_pins.find_by!(id: params[:pin_id] || params[:review_id])

        @checkin = journey.checkins.record!(user: current_user, pin: pin, **checkin_params)
      end

      def update
        journey = current_user.journeys.find_by!(id: params[:journey_id])

        @checkin = journey.checkins.find_by!(id: params[:id])
        @checkin.revise!(user: current_user, **checkin_params)
      end

      def destroy
        journey = current_user.journeys.find_by!(id: params[:journey_id])

        journey.checkins.find_by!(id: params[:id]).discard!(user: current_user)
      end

      private

      def checkin_params
        params
          .permit(:note, :checked_in_at, image_ids: [])
          .to_h
          .symbolize_keys
      end
    end
  end
end
