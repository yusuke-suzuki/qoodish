# frozen_string_literal: true

class RequestContext < ActiveSupport::CurrentAttributes
  attribute :user, :user_id, :request_id, :locale, :jwt_payload
end
