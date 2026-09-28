module Users
  class MutesController < ApplicationController
    before_action :authenticate_user!

    def create
      current_user.mute!(user) unless current_user.muting?(user)

      render 'users/show'
    end

    def destroy
      current_user.active_mutes.where(muted_id: user.id).each do |mute|
        Unmute.create_or_find_by!(mute: mute)
      end

      render 'users/show'
    end

    private

    def user
      @user ||= User.find_by!(id: params[:user_id])
    end
  end
end
