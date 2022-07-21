class EventsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :find_event, only: %i[show edit destroy update]
  before_action :build_event, only: %i[new create]
  before_action :perms_show?, only: :show
  before_action :perms_edit?, only: %i[edit update destroy]

  def index
    @events = Event.includes(:creator).all
  end

  def show; end

  def edit; end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'Event updated!'
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def new; end

  def create
    if @event.update(event_params)
      redirect_to @event, notice: 'Event created!'
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
    @event = Event.includes(:creator).find(params[:id])
  end

  def event_params
    params.require(:event).permit(:date, :location, :event_privacy, :desc, :name, :display_privacy, :attendee_privacy)
  end

  def perms_show?
    unless @event.viewable_by?(current_user)
      redirect_to(root_path,
                  alert: 'You do not have permission to view that page.')
    end
  end

  def perms_edit?
    unless @event.editable_by?(current_user)
      redirect_to(root_path,
                  alert: 'You do not have permission to edit that page.')
    end
  end

  # what is this here for?
  def build_event
    @event = current_user.events_created.build
  end
end
