# frozen_string_literal: true

module RevisableStatus
  extend ActiveSupport::Concern

  include Revisable

  def discard!(user:)
    revise!(user: user, status: :deleted)
  end

  private

  def guarded_attributes
    super + [:status]
  end

  def revision_content
    super.merge(status: status)
  end
end
