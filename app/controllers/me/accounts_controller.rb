module Me
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def destroy
      ActiveRecord::Associations::Preloader.new(
        records: [current_user],
        associations: [
          { pins: %i[revisions votes notifications] },
          { maps: [:images, :coauthorships, :bookmarks, :coauthorship_invitations, :votes, :notifications,
                   :featured_maps, { pins: %i[revisions votes notifications] }] },
          { journeys: [:milestones, { checkins: :images }] },
          { chapters: %i[votes images notifications] },
          { owned_images: :pin_revision_images }
        ]
      ).call

      current_user.destroy!
    end
  end
end
