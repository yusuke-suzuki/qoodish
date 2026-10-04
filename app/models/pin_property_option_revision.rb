# frozen_string_literal: true

class PinPropertyOptionRevision < ApplicationRecord
  include Revision

  belongs_to :pin_property_option
  belongs_to :user, optional: true

  alias_method :revisable, :pin_property_option

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :pin_property_option_id, :user_id, :name, :position, :status

  validates :name,
            presence: true
  validates :position,
            presence: true
end
