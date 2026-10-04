# frozen_string_literal: true

class PinProperty < ApplicationRecord
  include Revisable
  include RevisableStatus

  self.revision_attributes = %i[name position status]

  def self.authored_by(_user) = {}

  belongs_to :map
  belongs_to :current_revision, class_name: 'PinPropertyRevision', optional: true
  has_many :revisions,
           -> { order(:id) },
           class_name: 'PinPropertyRevision',
           dependent: :destroy,
           inverse_of: :pin_property
  has_many :options,
           -> { order(:position, :id) },
           class_name: 'PinPropertyOption',
           dependent: :destroy,
           inverse_of: :pin_property

  enum :status, { published: 'published', deleted: 'deleted' }, validate: true

  attr_readonly :map_id, :multiple

  normalizes :name, with: ->(name) { name.strip }

  validates :name,
            presence: {
              message: I18n.t('messages.api.pin_property_name_required')
            },
            length: {
              allow_blank: false,
              maximum: 30,
              message: I18n.t('messages.api.pin_property_name_exceed')
            }
  validates :position,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
