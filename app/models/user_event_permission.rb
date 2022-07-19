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
    if permission_type == 'attend' && UserEventPermission.find_by(user_id:, event_id:,
                                                                  permission_type: 'accept_invite')
      errors.add(:base, 'Cannot create attendance permission while an invite is pending.')
    elsif permission_type == 'accept_invite' && UserEventPermission.find_by(user_id:, event_id:,
                                                                            permission_type: 'attend')
      errors.add(:base, 'Cannot extend invite while user is already attending.')
    end
  end

  # identify target of the new permission being created
  # create new pending permission
  # validate new permission
  # save new permission
  # return flash response
  def self.create_permission(params, curr_user)
    permission_target_id = UserEventPermission.invite_target_id(params, curr_user.id)
    permission = UserEventPermission.new({ event_id: params[:event_id],
                                           permission_type: params[:permission_type],
                                           user_id: permission_target_id })
    permission.execute_action_by_tar(:create, curr_user)
  end

  def self.destroy_permission(params, curr_user)
    permission_target_id = UserEventPermission.invite_target_id(params, curr_user.id)
    permission = UserEventPermission.find_by(event_id: params[:event_id],
                                             permission_type: params[:permission_type],
                                             user_id: permission_target_id)
    return [:alert, 'Permission does not exist.'] if permission.nil?

    permission.execute_action_by_tar(:destroy, curr_user)
  end

  def execute_action_by_tar(action, curr_user)
    validity = valid? && validate_permission(curr_user, action)
    flash_value = generate_permission_response(action, validity)
    flash_status = generate_permission_status(action)
    [flash_status, flash_value]
  end

  # validates user has permission permission
  def generate_permission_response(action, valid)
    if valid
      "Successfully #{pretty_action_to_s(action)} permission."
    elsif !errors.empty?
      errors.full_messages.join(', ')
    else
      raise 'Invalid permission response'
    end
  end

  def generate_permission_status(action)
    case action
    when :create
      save_valid_permission
    when :destroy
      destroy_valid_permission
    else
      raise 'Invalid permission status'
    end
  end

  def validate_permission(curr_user, action)
    held_permissions = User.held_event_perms(curr_user, event_id)
    held_permissions.push('current_user') if curr_user == user
    required_perms = event.required_perms_for_action(permission_type, action)

    validate_held_vs_req(held_permissions, required_perms)
  end

  # assumes required_perms is an array of arrays
  # each array in req perms is a set of perms that allow a particular action
  # if held perms is a subset of any req perm array then the action is valid
  def validate_held_vs_req(held_permissions, required_permissions_arrays)
    required_permissions_arrays.each do |required_perms|
      common_vals = held_permissions & required_perms
      return true if common_vals.is_a?(Array) && common_vals.length == required_perms.length
    end
    errors.add :base, 'You do not have permission to perform this action.'
    false
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
    found_id = []
    found_id.push(params[:user_id]) if params[:user_id].present?
    found_id.push(User.find_by(email: params[:email])&.id) if params[:email].present?

    found_id.length == 1 ? found_id.first : raise("Invalid parameters #{params.inspect}")
  end

  # identifier should never have more than 1 value
  # more than one value is an error
  def self.validate_identifier(params)
    # can add additional identifier types here
    params = params.require(:identifier).permit(:email, :user_id)
    return params if params.keys.length == 1

    raise 'Invalid identifier'
  end

  private

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
