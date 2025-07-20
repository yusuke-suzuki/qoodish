# frozen_string_literal: true

class RequestContext < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :locale, :jwt_payload
end
