module Me
  class JournalsController < ApplicationController
    before_action :authenticate_user!

    def show
      @journal = Journal
                 .preload(:bookmarks, user: :images)
                 .find_by!(user: current_user)
    end

    def update
      @journal = Journal.find_by!(user: current_user)
      @journal.update!(journal_params)
    end

    private

    def journal_params
      params.permit(:title, :description)
    end
  end
end
