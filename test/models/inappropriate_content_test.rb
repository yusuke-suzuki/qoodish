# == Schema Information
#
# Table name: inappropriate_contents
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  content_id_val :integer          not null
#  content_type   :string           not null
#  reason_id_val  :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_inappropriate_contents_on_user_id  (user_id)
#

require 'test_helper'

class InappropriateContentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
