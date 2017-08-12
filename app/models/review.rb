# == Schema Information
#
# Table name: reviews
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  map_id       :integer          not null
#  place_id_val :string           not null
#  comment      :string           not null
#  image_url    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_reviews_on_map_id                               (map_id)
#  index_reviews_on_place_id_val                         (place_id_val)
#  index_reviews_on_place_id_val_and_map_id_and_user_id  (place_id_val,map_id,user_id) UNIQUE
#  index_reviews_on_user_id                              (user_id)
#

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :map

  before_validation :remove_carriage_return

  validates :comment,
            presence: {
              strict: Exceptions::CommentNotSpecified
            },
            length: {
              allow_blank: false,
              maximum: 140,
              strict: Exceptions::CommentExceeded
            }
  validates :user_id,
            presence: true
  validates :place_id_val,
            presence: {
              strict: Exceptions::PlaceIdNotSpecified
            },
            uniqueness: {
              scope: [:map_id, :user_id],
              strict: Exceptions::DuplicateReview
            }
  validates :map_id,
            presence: {
              strict: Exceptions::MapNotSpecified
            }
  validates :image_url,
            format: {
              allow_blank: true,
              with: /\A#{URI::regexp(%w(http https))}\z/,
              scrict: Exceptions::InvalidUri
            }


  def spot
    @spot ||= Spot.new(place_id_val, image_url)
  end

  private

  def remove_carriage_return
    return unless comment
    comment.gsub!(/\r/, '')
  end
end
