# == Schema Information
#
# Table name: maps
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  name        :string(255)      not null
#  description :string(255)      not null
#  private     :boolean          default(TRUE)
#  invitable   :boolean          default(FALSE)
#  shared      :boolean          default(FALSE)
#  base_id_val :string(255)
#  base_name   :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_maps_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Map < ApplicationRecord
  belongs_to :user
  has_many :reviews
  has_many :notifications, as: :notifiable
  has_many :invites, as: :invitable, dependent: :destroy

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
              maximum: 200,
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

  scope :postable, lambda { |current_user|
    includes(:user, :reviews).order(created_at: :desc).select { |map| current_user.postable?(map) }
  }

  scope :referenceable_by, lambda { |current_user|
    includes(:user, :reviews)
      .where(maps: { id: current_user.following_maps.ids })
      .or(includes(:user, :reviews).where(maps: { private: false }))
      .order(created_at: :desc)
  }

  def base
    @base ||= Spot.new(base_id_val)
  end

  def spots
    reviews.order(created_at: :desc).group_by(&:place_id_val).map { |key, value| value[0].spot }
  end

  def image_url
    reviews.exists? && reviews[0].image_url.present? ? reviews[0].image_url : ENV['SUBSTITUTE_URL']
  end

  def thumbnail_url
    reviews.exists? && reviews[0].image_url.present? ? reviews[0].thumbnail_url : ENV['SUBSTITUTE_URL']
  end

  private

  def remove_carriage_return
    name.gsub!(/\r/, '') if name
    description.gsub!(/\r/, '') if description
  end
end
