class RemoveIndexAndPermissionLevelFromUserEventPermissions < ActiveRecord::Migration[7.0]
  def change
    remove_index :user_event_permissions, column: %i[user_id event_id permission_level], name: 'index_unque_perms'
    remove_column :user_event_permissions, :permission_level, :string
  end
end
