class InappropriateContent < ApplicationRecord
  validates :user_id,
            presence: true
  validates :content_id_val,
            presence: true
  validates :content_type,
            presence: true
  validates :reason_id_val,
            presence: true
end
