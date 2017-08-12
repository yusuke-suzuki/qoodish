class ApplicationController < ActionController::API
  helper_method :current_user, :authenticate_user!

  if Rails.env.production?
    rescue_from Exception do |ex|
      logger.error("#{ex.class}: #{ex.message}")
      render_error(Exceptions::InternalServerError.new)
    end
  end

  rescue_from Exceptions::ApplicationError do |ex|
    logger.error("#{ex.class}: #{ex.message}")
    render_error(ex)
  end

  rescue_from ActiveRecord::RecordNotFound do |ex|
    logger.error("#{ex.class}: #{ex.message}")
    render_error(Exceptions::NotFound.new)
  end

  rescue_from ActiveRecord::RecordInvalid do |ex|
    logger.error("#{ex.class}: #{ex.message}")
    render_error(Exceptions::BadRequest.new)
  end

  private

  def current_user
    @current_user
  end

  def authenticate_user!
    raise Exceptions::Unauthorized if request.headers['Authorization'].blank?
    auth_client = Firebase::Auth.new
    decoded = auth_client.verify_id_token(request.headers['Authorization'].split(' ', 2).last)
    @current_user = User.find_by(uid: decoded[:uid])
    raise Exceptions::Unauthorized if @current_user.blank?
  end

  def render_error(ex)
    @title = ex.class.name.demodulize
    @message = ex.message
    render 'error', status: ex.status
  end
end
