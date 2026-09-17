class CreateModerationDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_decisions do |t|
      t.references :moderatable, polymorphic: true, null: false, index: false
      t.references :author, foreign_key: { to_table: :users }
      t.references :moderator, foreign_key: { to_table: :users }
      t.string :outcome, null: false
      t.text :reason, null: false
      t.text :content_snapshot
      t.bigint :reviewed_revision_id
      t.datetime :created_at, null: false
    end

    add_index :moderation_decisions, %i[moderatable_type moderatable_id created_at],
              name: 'index_moderation_decisions_on_moderatable_and_time'
  end
end
