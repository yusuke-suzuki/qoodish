class ApplicationController < ActionController::API
  before_action :set_locale
  helper_method :current_user, :authenticate_user!

  if Rails.env.production?
    rescue_from Exception do |ex|
      logger.fatal("#{ex.class}: #{ex.message}")
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

  def routing_error
    raise Exceptions::NotFound, "No route matches [#{request.request_method}] '#{request.path}'"
  end

  def healthcheck
    render plain: 'ok'
  end

  private

  def set_locale
    I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales)
  end

  attr_reader :current_user

  def authenticate_user!
    raise Exceptions::Unauthorized if request.headers['Authorization'].blank?

    verifier = GoogleAuth.new
    payload = verifier.verify_jwt(request.headers['Authorization'].split(' ', 2).last)

    @current_user = User.find_by(uid: payload['sub'])

    if @current_user.blank?
      @current_user = User.sign_in_anonymously(payload)
    end
  end

  def require_sign_in!
    raise Exceptions::SignInRequired if @current_user.is_anonymous
  end

  def render_error(ex)
    @title = ex.class.name.demodulize
    @message = ex.message
    render 'errors/error', status: ex.status
  end
end
