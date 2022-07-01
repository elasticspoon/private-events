class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    flash_response, flash_value = AttendedEvent.process_create_invite(attended_event_params, current_user)
    if flash_response.is_a?(AttendedEvent)
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
    flash_response, flash_value = AttendedEvent.process_destroy_invite(attended_event_params, current_user)

    flash[flash_response] = flash_value
    redirect_back fallback_location: root_path
  end

  private

  def attended_event_params
    params.require(:attended_event).permit(:event_id, :accepted, identifier: {})
  end
end
