class ApplicationController < ActionController::API
  before_action :set_locale, :set_user_context
  helper_method :current_user, :authenticate_user!

  if Rails.env.production?
    rescue_from Exception do |ex|
      Rails.logger.fatal(ex)
      render_error(Exceptions::InternalServerError.new)
    end
  end

  rescue_from Exceptions::ApplicationError do |ex|
    Rails.logger.error(ex)
    render_error(ex)
  end

  rescue_from ActiveRecord::RecordNotFound do |ex|
    Rails.logger.error(ex)
    render_error(Exceptions::NotFound.new)
  end

  rescue_from ActiveRecord::RecordInvalid do |ex|
    Rails.logger.error(ex)
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

  def set_user_context
    # 認証が必要なアクションでない場合や、認証前に実行される場合は無視
    return unless respond_to?(:current_user, true)

    # current_user が設定される前に実行される可能性があるため、安全に取得
    user = instance_variable_get(:@current_user)
    Thread.current[:user_id] = user&.id
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
