class AttendedEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user, uniqueness: { scope: :event, message: 'Invite already exists' }
  validates :accepted, inclusion: [true, false]

  def self.process_create_invite(params, curr_user)
    invite_target_id = AttendedEvent.invite_target_id(params, curr_user)
    pending_invite = AttendedEvent.new({ event_id: params[:event_id], accepted: params[:accepted],
                                         user_id: invite_target_id })
    # maybe the validation returns the response
    # the save returns the key?
    flash_value = pending_invite.validate_create_invite(curr_user)
    flash_response = pending_invite.save_valid_invite
    [flash_response, flash_value]
  end

  def self.process_destroy_invite(params, curr_user)
    target_id = AttendedEvent.invite_target_id(params, curr_user)
    invite = AttendedEvent.find_by(event_id: params[:event_id], user_id: target_id)
    return [:alert, 'Invite not found'] if invite.nil?

    flash_value = invite.validate_invite_destroy(curr_user)
    flash_response = invite.destroy_valid_invite
    [flash_response, flash_value]
  end

  # destroy
  # sucess deleting an extended invite - invite revoked
  # sucess leaving event - you are no longer attending
  # failure invite nil - invite not found

  # create
  # sucess creating invite - invite created
  # sucess joining event - now attending event
  def self.invite_target_id(params, curr_user)
    return curr_user.id unless params[:identifier].present?

    params = AttendedEvent.validate_identifier(params)

    AttendedEvent.identifier_id(params)
  end

  def self.identifier_id(params)
    return params[:user_id] if params[:user_id].present?
    return User.find_by(email: params[:email]).id if params[:email].present?
  end

  def self.validate_identifier(params)
    params = params.require(:identifier).permit(:email, :user_id)
    return params if params.keys.length == 1

    raise 'Invalid identifier'
  end

  # runs validations on invite based on current user perms
  def validate_invite_destroy(curr_user)
    case user_invite_perms(curr_user)
    when 'owner'
      validate_admin_destroy
    when 'pending_invite', 'attendee'
      validate_user_destroy
    end
  end

  # runs validations for current object: invite attempted to be created
  # curr_user is the user attempting to create the invite
  # invite user and event are registered in the object
  # returns the flash response
  def validate_create_invite(curr_user)
    case user_invite_perms(curr_user)
    when 'owner'
      validate_owner_create(curr_user)
    when 'pending_invite', 'open_invite'
      flash_response = validate_invited_create(curr_user)
      accept_valid_invite
      flash_response
    else
      'You do not have permission to perform this action'
    end
  end

  # returns the perms the inputed user has on
  # the event current object is associated with
  def user_invite_perms(curr_user)
    perms = curr_user.event_perms(event_id)
    perms ||= 'open_invite' unless event.private
    perms
  end

  # if invited
  # current user but be invited user to create invite
  def validate_invited_create(curr_user)
    return add_perms_error unless user_id == curr_user.id

    'You are attending this event.'
  end

  # valid if accepted is false
  # invalid if accepted true unless user_id == curr_user
  def validate_owner_create(curr_user)
    if accepted == false
      'Invite created.'
    elsif accepted == true && user_id == curr_user.id
      'You are now attending this event.'
    elsif accepted == true && user_id != curr_user.id
      add_perms_error
    else
      raise 'Invalid invite accepted'
    end
  end

  def validate_admin_destroy
    case accepted
    when true
      'You are no longer attending this event.'
    when false
      'Invite revoked.'
    else
      raise 'Invalid accept status'
    end
  end

  def validate_user_destroy
    'You are no longer attending this event.'
  end

  def destroy_valid_invite
    if errors.empty?
      destroy
      :notice
    else
      :alert
    end
  end

  def save_valid_invite
    if errors.empty?
      save
      self
    else
      :alert
    end
  end

  def accept_valid_invite
    self.accepted = true if errors.empty?
  end

  private

  def add_perms_error
    errors.add :base, 'You do not have permission to perform this action'
    'You do not have permission to perform this action'
  end
end
