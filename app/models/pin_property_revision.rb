# frozen_string_literal: true

class PinPropertyRevision < ApplicationRecord
  include Revision

  belongs_to :pin_property
  belongs_to :user, optional: true

  alias_method :revisable, :pin_property

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :pin_property_id, :user_id, :name, :position, :status

  validates :name,
            presence: true
  validates :position,
            presence: true
end
