class EventsController < ApplicationController
  before_action :find_event, only: :show
  def index
    @events = Event.includes(:creator, :attendees).all
  end

  def show; end

  def edit; end

  private

  def find_event
    @event = Event.find(params[:id])
  end
end
