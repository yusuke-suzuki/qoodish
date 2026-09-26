class RemoveModeratorEmailFromModerationDecisions < ActiveRecord::Migration[8.1]
  def change
    remove_column :moderation_decisions, :moderator_email, :string
  end
end
