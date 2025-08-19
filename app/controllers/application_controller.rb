class ApplicationController < ActionController::API
  helper_method :current_user, :authenticate_user!

  rescue_from Exceptions::ApplicationError, with: :handle_application_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  def routing_error
    exception = Exceptions::NotFound.new("No route matches [#{request.request_method}] '#{request.path}'")
    Rails.logger.warn(exception)
    render_error(exception)
  end

  def healthcheck
    render plain: 'ok'
  end

  private

  def handle_application_error(exception)
    severity = exception.status >= 500 ? :fatal : :error
    Rails.logger.send(severity, exception)
    render_error(exception)
  end

  def handle_record_not_found(exception)
    Rails.logger.warn(exception)
    render_error(Exceptions::NotFound.new)
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn(exception)
    render_error(Exceptions::BadRequest.new(exception.message))
  end

  def handle_record_invalid(exception)
    Rails.logger.warn(exception)
    render_error(Exceptions::UnprocessableContent.new(exception.message))
  end

  def current_user
    RequestContext.user
  end

  def authenticate_user!
    raise Exceptions::Unauthorized if current_user.blank?
  end

  def render_error(ex)
    @title = ex.class.name.demodulize
    @message = ex.message
    render 'errors/error', status: ex.status
  end
end
