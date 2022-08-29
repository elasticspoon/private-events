module EventsHelper
  def render_with_display_perms(event)
    render 'event', resource: event if event.viewable_by?(current_user)
  end

  def render_event_rand_size(event)
    if rand(30) > 5
      render partial: 'events/event_small', locals: { resource: event }
    else
      render partial: 'events/event', locals: { event: }
    end
  end
end
