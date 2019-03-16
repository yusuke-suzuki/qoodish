module Maps
  class InvitesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!

    def create
      ActiveRecord::Base.transaction do
        map = current_user.following_maps.find_by!(id: params[:map_id], private: true)
        raise Exceptions::NotFound unless current_user.map_owner?(map) || map.invitable
        recipient = User.find_by!(id: params[:user_id])
        invite = Invite.create!(
          invitable: map,
          sender: current_user,
          recipient: recipient
        )
        Notification.create!(
          notifiable: map,
          notifier: current_user,
          recipient: recipient,
          key: 'invited'
        )
      end
    end
  end
end
