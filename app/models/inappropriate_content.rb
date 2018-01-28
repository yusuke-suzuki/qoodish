# == Schema Information
#
# Table name: inappropriate_contents
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  content_id_val :integer          not null
#  content_type   :string(255)      not null
#  reason_id_val  :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_inappropriate_contents_on_user_id  (user_id)
#

class InappropriateContent < ApplicationRecord
  validates :user_id,
            presence: {
              strict: Exceptions::BadRequest
            }
  validates :content_id_val,
            presence: {
              strict: Exceptions::BadRequest
            }
  validates :content_type,
            presence: {
              strict: Exceptions::BadRequest
            }
  validates :reason_id_val,
            presence: {
              strict: Exceptions::BadRequest
            }
end
