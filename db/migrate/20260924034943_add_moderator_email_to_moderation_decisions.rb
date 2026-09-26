class AddModeratorEmailToModerationDecisions < ActiveRecord::Migration[8.1]
  def change
    add_column :moderation_decisions, :moderator_email, :string
  end
end
