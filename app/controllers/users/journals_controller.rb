module Users
  class JournalsController < ApplicationController
    before_action :authenticate_user!

    def show
      user = if params[:user_id] == current_user.uid
               current_user
             else
               User.find_by!(id: params[:user_id])
             end

      @journal = Journal
                 .preload(:bookmarks, user: :images)
                 .find_by!(user: user)
    end
  end
end
