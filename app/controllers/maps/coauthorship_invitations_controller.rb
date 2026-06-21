module Maps
  class CoauthorshipInvitationsController < ApplicationController
    before_action :authenticate_user!

    def create
      map = current_user.editable_maps.find_by!(id: params[:map_id])
      invitee = User.find_by!(id: params[:user_id])

      @invitation = CoauthorshipInvitation.create!(
        map: map,
        inviter: current_user,
        invitee: invitee
      )
    end
  end
end
