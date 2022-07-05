class CreateUserEventPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_event_permissions do |t|
      t.string :permission_level
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
