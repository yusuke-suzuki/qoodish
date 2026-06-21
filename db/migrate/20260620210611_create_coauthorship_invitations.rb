class CreateCoauthorshipInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :coauthorship_invitations do |t|
      t.references :map, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0

      t.timestamps

      t.index %i[map_id invitee_id]
      t.index %i[invitee_id status]
    end
  end
end
