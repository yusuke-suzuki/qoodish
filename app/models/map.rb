# == Schema Information
#
# Table name: maps
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  name        :string           not null
#  description :string           not null
#  private     :boolean          default(TRUE)
#  invitable   :boolean          default(FALSE)
#  shared      :boolean          default(FALSE)
#  base_id_val :string
#  base_name   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_maps_on_user_id  (user_id)
#

class Map < ApplicationRecord
  belongs_to :user
  has_many :reviews

  attr_accessor :base_lat, :base_lng

  acts_as_followable

  validates :name,
            presence: {
              strict: Exceptions::MapNameNotSpecified
            },
            uniqueness: {
              scope:  :user_id,
              strict: Exceptions::DuplicateMapName,
              on: :create
            },
            length: {
              allow_blank: false,
              maximum: 30,
              strict: Exceptions::MapNameExceeded
            }
  validates :description,
            presence: {
              strict: Exceptions::MapDescriptionNotSpecified
            },
            length: {
              allow_blank: false,
              maximum: 140,
              strict: Exceptions::MapDescriptionExceeded
            }
  validates :user_id,
            presence: {
              strict: Exceptions::MapOwnerNotSpecified
            }

  before_validation :remove_carriage_return

  scope :popular, lambda {
    includes(:user, :reviews).where(maps: { private: false }).sort_by(&:followers_count).take(30).reverse!
  }

  def base
    @base ||= Spot.new(base_id_val)
  end

  def spots
    reviews.group_by(&:place_id_val).map { |key, value| value[0].spot }
  end

  private

  def remove_carriage_return
    description.gsub!(/\r/, '') if name
    description.gsub!(/\r/, '') if description
  end
end
