class InvitesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_sign_in!

  def index
    @invites =
      current_user
        .invites
        .includes(:invitable)
        .order(created_at: :desc)
        .reject { |invite| invite.sender.blank? || invite.invitable.blank? }
  end
end
