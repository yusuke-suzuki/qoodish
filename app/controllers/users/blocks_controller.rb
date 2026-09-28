module Users
  class BlocksController < ApplicationController
    before_action :authenticate_user!

    def create
      current_user.block!(user) unless current_user.blocking?(user)

      render 'users/show'
    end

    def destroy
      current_user.active_blocks.where(blocked_id: user.id).each do |block|
        Unblock.create_or_find_by!(block: block)
      end

      render 'users/show'
    end

    private

    def user
      @user ||= User.find_by!(id: params[:user_id])
    end
  end
end
