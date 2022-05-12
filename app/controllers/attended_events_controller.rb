class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = AttendedEvent.new
    if event.update(attended_event_params)
      redirect_to event_path(event.event_id), notice: 'You are now attending the event.'
    else
      redirect_to event_path(event.event_id), alert: event.errors.full_messages.join(' ')
    end
  end

  def destroy
    event = AttendedEvent.find_by(user_id: current_user.id, event_id: params[:event_id])
    if event
      event.destroy
      redirect_to root_path, notice: 'You are no longer attending the event.'
    else
      redirect_to event_path(event.event_id), alert: 'You are not attending that event.'
    end
  end

  private

  def attended_event_params
    params.require(:attended_event).permit(:event_id, :accepted?).merge({ user_id: current_user.id })
  end
end
