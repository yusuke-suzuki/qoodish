module Users
  class ChaptersController < ApplicationController
    before_action :authenticate_user!

    def index
      user = if params[:user_id] == current_user.uid
               current_user
             else
               User.find_by!(id: params[:user_id])
             end

      @chapters = Chapter
                  .referenceable_by(current_user)
                  .where(user: user)
                  .preload(:map, :votes, user: %i[images journal])
                  .order(created_at: :desc)
    end
  end
end
