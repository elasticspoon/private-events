module EventsHelper
  def render_with_display_perms(event)
    render 'event', resource: event if event.viewable_by?(current_user)
  end
end
