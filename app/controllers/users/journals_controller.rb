module Users
  class JournalsController < ApplicationController
    before_action :authenticate_user!

    def show
      user = User.find_by!(id: params[:user_id])

      @journal = Journal
                 .not_blocking(current_user)
                 .preload(:bookmarks, user: :image)
                 .find_by!(user: user)
    end
  end
end
