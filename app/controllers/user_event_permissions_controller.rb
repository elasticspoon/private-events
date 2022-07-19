class UserEventPermissionsController < ApplicationController
  before_action :authenticate_user!
  def create
    flash_response, flash_value = UserEventPermission.create_permission(user_event_perm_params, current_user)
    if flash_response.is_a?(UserEventPermission)
      flash.notice = flash_value
      redirect_to event_path(flash_response.event_id)
    elsif flash_response == :alert
      flash[flash_response] = flash_value
      redirect_back fallback_location: root_path
    else
      raise "Invalid flash response: #{flash_response}"
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
