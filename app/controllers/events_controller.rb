class EventsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :find_event, only: :show
  before_action :build_event, only: %i[new create]

  def index
    @events = Event.includes(:creator, :attendees).all
  end

  def show; end

  def edit; end

  def new; end

  def create
    if @event.update(event_params)
      redirect_to [current_user, @event], notice: 'Event created!'
    else
      render 'new', status: :unprocessable_entity
    end
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
end
