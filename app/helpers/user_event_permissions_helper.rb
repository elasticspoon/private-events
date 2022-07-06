module UserEventPermissionsHelper
  def can_revoke_invite?(event_id)
    current_user.holds_permission_currently?('owner', event_id) ||
      current_user.holds_permission_currently?('moderate', event_id)
  end

  def can_join?(event)
    current_user.holds_permission_currently?('accept_invite', event.id)
  end
end
