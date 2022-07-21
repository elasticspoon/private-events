class UserEventPermissionsController < ApplicationController
  before_action :authenticate_user!
  def create
    flash_response, flash_value = UserEventPermission.create_permission(user_event_perm_params, current_user)
    flash[flash_response] = flash_value
    if flash_response == :notice
      redirect_to event_path(user_event_perm_params[:event_id])
    else
      redirect_back fallback_location: root_path
    end
  end

  def destroy
    flash_response, flash_value = UserEventPermission.destroy_permission(user_event_perm_params, current_user)

    flash[flash_response] = flash_value
    redirect_back fallback_location: root_path
  end

  private

  def user_event_perm_params
    params.require(:user_event_permissions).permit(:event_id, :permission_type, identifier: {})
  end
end
