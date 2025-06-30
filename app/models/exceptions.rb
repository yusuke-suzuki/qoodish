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

  class FirebaseAuthError < Unauthorized
    def initialize(message = I18n.t('messages.api.firebase_auth_error'))
      super(message)
    end
  end

  class OidcAuthError < Unauthorized
    def initialize(message = I18n.t('messages.api.oidc_auth_error'))
      super(message)
    end
  end

  class DuplicateMapName < Conflict
    def initialize(*)
      super(I18n.t('messages.api.duplicate_map_name'))
    end
  end

  class MapNameNotSpecified < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_name_required'))
    end
  end

  class MapNameExceeded < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_name_exceed'))
    end
  end

  class MapDescriptionNotSpecified < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_description_required'))
    end
  end

  class MapDescriptionExceeded < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_description_exceed'))
    end
  end

  class MapOwnerNotSpecified < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_owner_not_specified'))
    end
  end

  class CommentNotSpecified < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.comment_required'))
    end
  end

  class CommentExceeded < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.comment_exceeded'))
    end
  end

  class InvalidUri < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.invalid_uri'))
    end
  end

  class MapOwnerCannotRemoved < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.map_owner_cannot_removed'))
    end
  end

  class RegistrationTokenNotSpecified < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.registration_token_is_required'))
    end
  end

  class DuplicateRegistrationToken < BadRequest
    def initialize(*)
      super(I18n.t('messages.api.registration_token_is_duplicated'))
    end
  end
end
