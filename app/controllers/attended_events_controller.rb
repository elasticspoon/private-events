class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = current_user.attended_events.new
    if event.update(attended_event_params)
      redirect_to event_path(event.event_id), notice: 'You are now attending the event.'
    else
      flash[:alert] = event.errors.full_messages.join(' ')
      flash.now[:alert] = event.errors.full_messages.join(' ')
    end
  end

  def destroy
    event = AttendedEvent.find_by(user_id: current_user.id, event_id: params[:event_id])
    if event
      event.destroy
      flash.now[:notice] = 'No longer attending event.'
    else
      flash.now[:alert] = 'You are not attending that event.'
    end
  end

  private

  def attended_event_params
    params.require(:attended_event).permit(:event_id)
  end
end
