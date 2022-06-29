class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = AttendedEvent.process_create_invite(attended_event_params, current_user)

    if event.errors.empty?
      redirect_to event_path(event.event_id), notice: event.generate_create_success_text
    else
      redirect_back fallback_location: root_path, alert: event.generate_create_error_text
    end
  end

  def destroy
    event = AttendedEvent.process_destroy_invite(attended_event_params, current_user)

    if event.nil? || !event.errors.empty?
      redirect_back fallback_location: root_path, alert: event&.errors || 'That invitation does not exist.'
    else
      redirect_back fallback_location: root_path, notice: 'Invite cancelled.'
    end
  end

  private

  def attended_event_params
    params.require(:attended_event).permit(:event_id, :accepted, identifier: {})
  end
end
