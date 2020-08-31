class MessagesController < ApplicationController
  def create
    Rails.logger.info("[Pub/Sub] Message received at #{Time.now}: #{params[:message]}")

    EventHandler.handle_event(params[:message][:data], params[:message][:attributes])
  end
end
