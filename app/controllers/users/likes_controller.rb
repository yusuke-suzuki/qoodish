module Users
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      @likes =
        if params[:user_id] == current_user.uid
          current_user.votes.order(created_at: :desc).limit(20).reject { |vote| vote.votable.blank? || vote.votable_type == Comment.name }
        else
          user = User.find_by!(id: params[:user_id])
          user.votes.includes(votable: :user).order(created_at: :desc).limit(20).select do |vote|
            return false if vote.votable.blank?

            if vote.votable_type == Comment.name
              false
            elsif vote.votable_type == Review.name
              current_user.referenceable?(vote.votable.map)
            elsif vote.votable_type == Map.name
              current_user.referenceable?(vote.votable)
            else
              true
            end
          end
        end
    end
  end
end
