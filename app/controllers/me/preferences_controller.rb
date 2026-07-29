module Me
  class PreferencesController < ApplicationController
    before_action :authenticate_user!

    def update
      current_user.update_web_push_preferences!(web_push_params)
    end

    private

    def web_push_params
      params
        .require(:web_push)
        .permit(:coauthor_invited, :liked, :comment, :published)
        .to_h
    end
  end
end
