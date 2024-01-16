class ApplicationController < ActionController::API
  around_action :switch_locale
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

  def switch_locale(&action)
    locale = extract_locale_from_accept_language_header || I18n.default_locale
    I18n.with_locale(locale, &action)
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

  def authenticate_pubsub!
    raise Exceptions::Unauthorized if request.headers['Authorization'].blank?

    verifier = GoogleAuth.new

    jwt = request.headers['Authorization'].split(' ', 2).last
    aud = ENV['SUBSCRIBER_ENDPOINT']

    payload = verifier.verify_oidc(jwt, aud)

    raise Exceptions::Unauthorized unless payload['email'] == ENV['PUBSUB_SA_EMAIL']
  end

  def render_error(ex)
    @title = ex.class.name.demodulize
    @message = ex.message
    render 'errors/error', status: ex.status
  end
end
