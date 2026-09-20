module Me
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    def update
      current_user.update!(profile_params)
      @user = current_user
    end

    private

    # Clients send the avatar as a one-element list, from when a profile held a
    # collection of images rather than a pointer to one of them.
    def profile_params
      permitted = params.permit(:name, :biography, image_ids: []).to_h.symbolize_keys
      return permitted unless permitted.key?(:image_ids)

      permitted[:image_id] = permitted.delete(:image_ids).first
      permitted
    end
  end
end
