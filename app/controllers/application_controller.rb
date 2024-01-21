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

  def set_locale
    locale = extract_locale_from_accept_language_header || I18n.default_locale
    Rails.logger.info("Switch locale to #{locale}")
    I18n.locale = locale
  end

  private

  def extract_locale_from_accept_language_header
    return nil if request.env['HTTP_ACCEPT_LANGUAGE'].blank?

    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

  attr_reader :current_user

  def authenticate_user!
    raise Exceptions::Unauthorized if request.headers['Authorization'].blank?

    verifier = GoogleAuth.new

    jwt = request.headers['Authorization'].split(' ', 2).last

    payload = verifier.verify_jwt(jwt)

    @current_user = User.find_by(uid: payload['sub'])

    raise Exceptions::Unauthorized if @current_user.blank?
  end

  def render_error(ex)
    @title = ex.class.name.demodulize
    @message = ex.message
    render 'errors/error', status: ex.status
  end
end
