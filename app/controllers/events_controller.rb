class EventsController < ApplicationController
  def index
    @events = Event.includes(:creator, :attendees).all
  end

  def show; end

  def edit; end
end
