# frozen_string_literal: true

module RevisableStatus
  extend ActiveSupport::Concern

  include Revisable

  def discard!(user:)
    revise!(user: user, status: :deleted)
  end
end
