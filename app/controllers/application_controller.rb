class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource

  def not_implemented
    flash.alert = 'Not implemented.'
    redirect_back fallback_location: root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username name])
  end

  private

  def layout_by_resource
    if devise_controller? && action_name == 'new'
      'login_layout'
    else
      'event_layout'
    end
  end
end
