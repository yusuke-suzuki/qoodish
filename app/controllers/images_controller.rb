class ImagesController < ApplicationController
  before_action :authenticate_user!

  def create
    result = Cloudflare::Images.new.create_direct_upload
    image = current_user.owned_images.create!(
      url: Cloudflare::Images.delivery_url(result[:id])
    )
    render json: { id: image.id, upload_url: result[:upload_url] }
  end
end
