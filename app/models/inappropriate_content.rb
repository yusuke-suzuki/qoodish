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
