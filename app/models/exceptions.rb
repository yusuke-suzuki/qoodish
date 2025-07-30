# frozen_string_literal: true

module Exceptions
  class ApplicationError < StandardError
    attr_reader :status, :code, :message

    def initialize(status = 500, message = 'An error occurred')
      super()
      @status = status
      @code = ActiveSupport::Inflector.demodulize(self)
      @message = message
    end
  end

  class BadRequest < ApplicationError
    def initialize(message = I18n.t('messages.api.error_400'))
      super(400, message)
    end
  end

  class Unauthorized < ApplicationError
    def initialize(message = I18n.t('messages.api.error_401'))
      super(401, message)
    end
  end

  class Forbidden < ApplicationError
    def initialize(message = I18n.t('messages.api.error_403'))
      super(403, message)
    end
  end

  class NotFound < ApplicationError
    def initialize(message = I18n.t('messages.api.error_404'))
      super(404, message)
    end
  end

  class Conflict < ApplicationError
    def initialize(message = I18n.t('messages.api.error_409'))
      super(409, message)
    end
  end

  class UnprocessableContent < ApplicationError
    def initialize(message = I18n.t('messages.api.error_422'))
      super(422, message)
    end
  end

  class InternalServerError < ApplicationError
    def initialize(message = I18n.t('messages.api.error_500'))
      super(500, message)
    end
  end
end
