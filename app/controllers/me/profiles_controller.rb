module Me
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    def update
      ActiveRecord::Associations::Preloader.new(
        records: [current_user],
        associations: [:images]
      ).call

      current_user.update!(profile_params)
      @user = current_user
    end

    private

    def profile_params
      params.permit(:name, :biography, image_ids: [])
    end
  end
end
