module Me
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def destroy
      ActiveRecord::Associations::Preloader.new(
        records: [current_user],
        associations: [
          { reviews: %i[images votes notifications] },
          { maps: [:images, :coauthorships, :bookmarks, :coauthorship_invitations, :votes, :notifications,
                   { reviews: %i[images votes notifications] }] },
          { journeys: [:milestones, { checkins: :images }] },
          { chapters: %i[votes images notifications] }
        ]
      ).call

      current_user.destroy!
    end
  end
end
