class UserEventPermission < ApplicationRecord
  PERMISSION_TYPES = %w[attend moderate accept_invite owner].freeze

  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :permission_type, inclusion: { in: PERMISSION_TYPES, message: 'is invalid.' }

  validates_uniqueness_of :user_id, scope: %i[permission_type event_id], message: 'already has permission.'
  validate :uniqueness_attend_accept_invite

  # validation to make accept_invite and attend mutually exclusive
  def uniqueness_attend_accept_invite
    if permission_type == 'attend' && UserEventPermission.find_by(user_id: user_id, event_id: event_id,
                                                                  permission_type: 'accept_invite')
      errors.add(:base, 'Cannot create attendance permission while an invite is pending.')
    elsif permission_type == 'accept_invite' && UserEventPermission.find_by(user_id: user_id, event_id: event_id,
                                                                            permission_type: 'attend')
      errors.add(:base, 'Cannot extend invite while user is already attending.')
    end
  end

  # identify target of the new permission being created
  # create new pending permission
  # validate new permission
  # save new permission
  # return flash response
  def self.create_permission(params, curr_user_id)
    permission_target_id = UserEventPermission.invite_target_id(params, curr_user_id)
    pending_permission = UserEventPermission.new({ event_id: params[:event_id],
                                                   permission_type: params[:permission_type],
                                                   user_id: permission_target_id })
    valid_permission = pending_permission.validate_permission(curr_user_id, :create)
    flash_value = generate_permission_response(valid_permission, :create)
    flash_status = pending_permission.save_valid_permission
    [flash_status, flash_value]
  end

  def self.destroy_permission(params, curr_user_id)
    permission_target_id = UserEventPermission.invite_target_id(params, curr_user_id)
    permission = UserEventPermission.find_by(event_id: params[:event_id],
                                             permission_type: params[:permission_type],
                                             user_id: permission_target_id)
    return [:alert, 'Permission does not exist.'] if permission.nil?

    valid_permission = permission.validate_permission(curr_user_id, :destroy)
    flash_value = generate_permission_response(valid_permission, :destroy)
    flash_status = permission.destroy_valid_permission
    [flash_status, flash_value]
  end

  ##############################################################################################
  # TODO
  # 1. add validation for only 1 usereventperm of attend or accept_invite type
  # 2. turn validate permission create into a validation
  ##############################################################################################

  # validates user has permission permission
  def generate_permission_response(has_perms, action)
    case has_perms && valid?
    when true
      "Successfully #{pretty_action_to_s(action)} permission."
    when false
      errors.empty? ? 'You do not have permission to perform this action.' : errors.full_messages.join(', ')
    else
      raise 'Invalid permission response'
    end
  end

  def validate_permission(curr_user_id, action)
    held_permissions = user.held_event_perms(event_id, curr_user_id)
    required_perms = event.required_perms_for_action(permission_type, action)

    required_perms.call(held_permissions)
  end

  ##############################################################################################
  # general methods
  ##############################################################################################
  def self.invite_target_id(params, curr_user_id)
    return curr_user_id unless params[:identifier].present?

    params = UserEventPermission.validate_identifier(params)

    UserEventPermission.identifier_id(params)
  end

  # we are fine with user_id being nil since permission could
  # be extended to a user that does not exist
  def self.identifier_id(params)
    if params[:user_id].present?
      params[:user_id]
    elsif params[:email].present?
      User.find_by(email: params[:email]).id
    else
      raise "Invalid parameters #{params.inspect}"
    end
  end

  # identifier should never have more than 1 value
  # more than one value is an error
  def self.validate_identifier(params)
    # can add additional identifier types here
    params = params.require(:identifier).permit(:email, :user_id)
    return params if params.keys.length == 1

    raise 'Invalid identifier'
  end

  def save_valid_permission
    if errors.empty?
      save
      self
    else
      :alert
    end
  end

  def destroy_valid_permission
    if errors.empty?
      destroy
      :notice
    else
      :alert
    end
  end

  def pretty_action_to_s(action)
    "#{action.to_s.sub(/e$/, '')}ed"
  end
end
