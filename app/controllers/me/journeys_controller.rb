module Me
  class JourneysController < ApplicationController
    before_action :authenticate_user!

    def index
      @journeys = current_user
                  .journeys
                  .preload(:map, :milestones, :checkins, :chapter)
                  .order(created_at: :desc)
    end

    def show
      @journey = current_user
                 .journeys
                 .preload(:map, :milestones, :checkins, :chapter)
                 .find_by!(id: params[:id])
    end

    def destroy
      current_user.journeys.find_by!(id: params[:id]).destroy!
    end

    def start
      @journey = current_user.journeys.unfinished.find_by!(id: params[:id])
      @journey.start!

      preload_journey_for_serialization
    end

    def finish
      @journey = current_user.journeys.unfinished.find_by!(id: params[:id])
      @journey.finish!(encoded_path: params[:encoded_path])

      preload_journey_for_serialization
    end

    private

    def preload_journey_for_serialization
      ActiveRecord::Associations::Preloader.new(
        records: [@journey],
        associations: [:map, :milestones, :checkins, :chapter]
      ).call
    end
  end
end
