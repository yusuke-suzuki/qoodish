# frozen_string_literal: true

module Revision
  extend ActiveSupport::Concern

  included do
    after_create :become_current
  end

  private

  def become_current
    revisable.update!(current_revision: self)
  end
end
