class CoauthorshipInvitationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @invitations =
      current_user
      .received_coauthorship_invitations
      .pending
      .includes({ map: :images }, { inviter: :images })
      .order(created_at: :desc)
  end

  def accept
    @invitation = pending_invitation
    @invitation.accept!
  end

  def decline
    @invitation = pending_invitation
    @invitation.decline!
  end

  private

  def pending_invitation
    current_user
      .received_coauthorship_invitations
      .pending
      .find_by!(id: params[:id])
  end
end
