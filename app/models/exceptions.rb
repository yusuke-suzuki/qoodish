module Exceptions
  class CommonError < ActiveModel::StrictValidationFailed
    attr_reader :status, :title
  end

  class ApplicationError < CommonError
  end

  class BadRequest < ApplicationError
    def initialize(message = I18n.t('messages.api.error_400'))
      super(message)
      @status = 400
    end
  end

  class Unauthorized < ApplicationError
    def initialize(message = I18n.t('messages.api.error_401'))
      super(message)
      @status = 401
    end
  end

  class Forbidden < ApplicationError
    def initialize(message = I18n.t('messages.api.error_403'))
      super(message)
      @status = 403
    end
  end

  class NotFound < ApplicationError
    def initialize(message = I18n.t('messages.api.error_404'))
      super(message)
      @status = 404
    end
  end

  class InternalServerError < CommonError
    def initialize(message = I18n.t('messages.api.error_500'))
      super(message)
      @status = 500
    end
  end
end
