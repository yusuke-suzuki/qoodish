module Me
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def destroy
      ActiveRecord::Associations::Preloader.new(
        records: [current_user],
        associations: [
          { reviews: %i[images votes notifications] },
          { maps: [:images, :coauthorships, :bookmarks, :coauthorship_invitations, :votes, :notifications,
                   :featured_maps, { reviews: %i[images votes notifications] }] },
          { journeys: [:milestones, { checkins: :images }] },
          { chapters: %i[votes images notifications] }
        ]
      ).call

      deleted = {
        id: current_user.id,
        map_ids: current_user.maps.map(&:id),
        review_ids: current_user.reviews.map(&:id),
        chapter_ids: current_user.chapters.map(&:id)
      }

      current_user.destroy!

      render json: deleted
    end
  end
end
