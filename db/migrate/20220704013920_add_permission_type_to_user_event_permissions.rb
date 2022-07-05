class AddPermissionTypeToUserEventPermissions < ActiveRecord::Migration[7.0]
  def change
    add_column :user_event_permissions, :permission_type, :string
  end
end
