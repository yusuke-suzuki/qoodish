class AddStaffMemberToModerationDecisions < ActiveRecord::Migration[8.1]
  def change
    add_reference :moderation_decisions, :staff_member, null: true, foreign_key: true
  end
end
