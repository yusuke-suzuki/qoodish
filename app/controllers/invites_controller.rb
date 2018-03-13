class InvitesController < ApplicationController
  before_action :authenticate_user!

  def index
    @invites = current_user.invites.includes(:invitable).reject { |invite| invite.sender.blank? || invite.invitable.blank? }
  end
end
