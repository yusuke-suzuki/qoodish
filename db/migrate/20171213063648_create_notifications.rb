class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.references :notifiable, polymorphic: true
      t.references :notifier, polymorphic: true
      t.references :recipient, polymorphic: true
      t.string :key
      t.boolean :read, default: false
      t.timestamps
    end

    add_index :notifications, %i[notifiable_id notifiable_type]
    add_index :notifications, %i[notifier_id notifier_type]
    add_index :notifications, %i[recipient_id recipient_type]
  end
end
