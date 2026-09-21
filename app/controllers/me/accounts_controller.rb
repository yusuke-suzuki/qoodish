module Me
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def destroy
      ActiveRecord::Associations::Preloader.new(
        records: [current_user],
        associations: [
          { pins: [:revisions, :votes, :notifications, { all_comments: %i[revisions votes notifications] }] },
          { maps: [:revisions, :coauthorships, :bookmarks, :coauthorship_invitations, :votes, :notifications,
                   :featured_maps,
                   { pins: [:revisions, :votes, :notifications,
                            { all_comments: %i[revisions votes notifications] }] }] },
          { journeys: [:milestones, { all_checkins: :revisions }] },
          { chapters: %i[votes revisions notifications] },
          { owned_images: %i[pin_revision_images map_revision_images chapter_revision_images
                             journey_checkin_revision_images] }
        ]
      ).call

      current_user.destroy!
    end
  end
end
