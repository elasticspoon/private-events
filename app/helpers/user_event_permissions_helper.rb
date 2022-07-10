module UserEventPermissionsHelper
  def generate_perms_invite_form(event, method, submit_text, class_value)
    render partial: 'user_event_permissions/generic_attend_perm_button',
           locals: { event:, method:, submit_text:, class_value: }
  end
end
