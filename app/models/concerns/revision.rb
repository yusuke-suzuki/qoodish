# frozen_string_literal: true

module Revision
  extend ActiveSupport::Concern

  included do
    after_create :become_current
  end

  private

  def become_current
    revisable.current_revision = self
    revisable.update_column(:current_revision_id, id)
  end
end
