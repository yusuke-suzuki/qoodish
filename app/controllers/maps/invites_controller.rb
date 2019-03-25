module Maps
  class InvitesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_sign_in!

    def create
      map = current_user.invitable_maps.find_by!(id: params[:map_id])
      recipient = User.find_by!(id: params[:user_id])

      Invite.create!(
        invitable: map,
        sender: current_user,
        recipient: recipient
      )
    end
  end
end
