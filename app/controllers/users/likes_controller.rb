module Users
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      @likes = if params[:user_id] == current_user.uid
                 current_user
                   .votes
                   .includes(votable: %i[user spot])
                   .order(created_at: :desc)
                   .limit(20)
                   .reject { |vote| vote.votable.blank? || vote.votable_type == Comment.name }
               else
                 user = User.find_by!(id: params[:user_id])

                 user
                   .votes
                   .includes(votable: [:user])
                   .order(created_at: :desc)
                   .limit(20)
                   .select { |vote| current_user.referenceable_vote?(vote) }
               end
    end
  end
end
