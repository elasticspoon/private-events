class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.events_attended << Event.find(attended_event_params[:event_id])
  end

  def destroy
    event = AttendedEvent.find_by(user_id: current_user.id, event_id: attended_event_params[:event_id])
    if event
      event.destroy
      flash[:notice] = 'No longer attending event.'
    else
      flash[:alert] = 'You are not attending that event.'
    end
  end

  private

  def attended_event_params
    params.require(:attended_event).permit(:event_id)
  end
end
