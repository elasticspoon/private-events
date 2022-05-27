class AttendedEventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = AttendedEvent.accept_or_create_invite(attended_event_params, current_user.id)

    if event.errors.empty?
      redirect_to event_path(event.event_id),
                  notice: (event.accepted ? 'You are now attending the event.' : 'Invite created.')
    else
      redirect_to event_path(event.event_id), alert: event.errors.full_messages.join(' ')
    end
  end

  def destroy
    response = AttendedEvent.invite_destroyable?(params[:user_id] || current_user.id, params[:event_id],
                                                 current_user.id)
    if response[:result]
      response[:result].destroy
      redirect_to root_path, notice: response[:response]
    else
      redirect_to event_path(params[:event_id]), alert: response[:response]
    end
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
