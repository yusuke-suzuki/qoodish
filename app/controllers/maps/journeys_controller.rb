module Maps
  class JourneysController < ApplicationController
    before_action :authenticate_user!

    def create
      map = current_user.referenceable_maps.find_by!(id: params[:map_id])

      @journey = current_user.journeys.create!(map: map)

      ActiveRecord::Associations::Preloader.new(
        records: [@journey],
        associations: [:map, :milestones, { checkins: :images }, :chapter]
      ).call
    end
  end
end
