# frozen_string_literal: true

class RequestContext < ActiveSupport::CurrentAttributes
  attribute :user, :request_id, :locale, :trace_context, :jwt_payload
end
