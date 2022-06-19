module EventsHelper
  def render_with_attendee_perms(event)
    render partial: 'events/attendees_listing', locals: { event: event } if event.attendee_display_perms?(current_user)
  end

  def render_permitted_event(event)
    render partial: 'event', locals: {event: event} if event.event_display_perms?(current_user)
  end
end
