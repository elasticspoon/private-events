class EventsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :find_event, only: %i[show edit destroy update]
  before_action :build_event, only: %i[new create]
  before_action :event_owner?, only: %i[edit update destroy]

  def index
    @events = Event.includes(:creator, :attendees).all
  end

  def show; end

  def edit; end

  def update
    if @event.update(event_params)
      redirect_to [current_user, @event], notice: 'Event created!'
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def new; end

  def create
    if @event.update(event_params)
      redirect_to [current_user, @event], notice: 'Event created!'
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to root_path, notice: 'Event deleted.'
  end

  private

  def find_event
    @event = Event.includes(:creator, :attendees).find(params[:id])
  end

  def event_params
    params.require(:event).permit(:date, :location)
  end

  def build_event
    @event = current_user.events_created.build
  end

  def event_owner?
    unless params[:user_id] == current_user.id.to_s
      redirect_back fallback_location: root_path,
                    alert: 'You do not have permission.'
    end
  end
end
