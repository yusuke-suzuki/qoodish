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

  class Conflict < ApplicationError
    def initialize(message = I18n.t('messages.api.error_409'))
      super(message)
      @status = 409
    end
  end

  class InternalServerError < CommonError
    def initialize(message = I18n.t('messages.api.error_500'))
      super(message)
      @status = 500
    end
  end

  class FirebaseAuthError < Unauthorized
    def initialize(message = I18n.t('messages.api.firebase_auth_error'))
      super(message)
    end
  end

  class PubSubAuthError < Unauthorized
    def initialize(message = I18n.t('messages.api.pubsub_auth_error'))
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
