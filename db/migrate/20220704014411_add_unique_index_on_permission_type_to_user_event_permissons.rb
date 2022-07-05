class AddUniqueIndexOnPermissionTypeToUserEventPermissons < ActiveRecord::Migration[7.0]
  def change
    add_index :user_event_permissions, %i[permission_type user_id event_id], unique: true,
                                                                             name: 'index_unique_perm_type'
  end
end
