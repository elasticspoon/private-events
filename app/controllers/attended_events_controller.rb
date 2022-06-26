class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = AttendedEvent.process_invite(attended_event_params, current_user.id)

    if event.errors.empty?
      redirect_to event_path(event.event_id), notice: event.generate_create_success_text
    else
      redirect_back fallback_location: root_path, alert: event.generate_create_error_text
    end
  end

  def destroy
    flash_status, flash_response =
      AttendedEvent.destroy_invite(params[:user_id], params[:event_id], current_user.id)

    flash[flash_status] = flash_response
    redirect_back fallback_location: root_path
  end

  private

  def attended_event_params
    fix_params.require(:attended_event).permit(:user_id, :event_id, :accepted)
  end

  def fix_params
    values = params[:attended_event]
    values[:accepted] = values[:accepted] ? true : false
    values[:user_id] = User.find_by(email: values[:email]).id if values.key?(:email)
    values[:user_id] = current_user.id unless values[:user_id]

    params
  end
end
