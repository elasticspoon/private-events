class AddIndexToUserEventPermissions < ActiveRecord::Migration[7.0]
  def change
    add_index :user_event_permissions, %i[user_id event_id permission_level], unique: true, name: 'index_unque_perms'
  end
end
