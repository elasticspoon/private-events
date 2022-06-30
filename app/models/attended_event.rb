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
    pending_invite.validate_create_invite(curr_user)
    pending_invite.save_valid_invite
  end

  def self.process_destroy_invite(params, curr_user)
    target_id = AttendedEvent.invite_target_id(params, curr_user)

    invite = AttendedEvent.find_by(event_id: params[:event_id], user_id: target_id)
    invite&.validate_invite_destroy(curr_user)
    invite&.destroy_valid_invite || nil
  end

  # destroy
  # sucess deleting an extended invite - invite revoked
  # sucess leaving event - you are no longer attending
  # failure invite nil - invite not found

  # create
  # sucess creating invite - invite created
  # sucess joining event - now attending event
  def generate_flash_response(_invite); end

  def self.invite_target_id(params, curr_user)
    return curr_user.id unless params[:identifier].present?

    params = AttendedEvent.validate_identifier(params)

    params&.permitted? ? AttendedEvent.identifier_id(params) : nil
  end

  def self.identifier_id(params)
    return params[:user_id] if params[:user_id].present?
    return User.find_by(email: params[:email]).id if params[:email].present?
  end

  def self.validate_identifier(params)
    params = params.require(:identifier).permit(:email, :user_id)
    params.keys.length == 1 ? params : nil
  end

  # runs validations on invite based on current user perms
  def validate_invite_destroy(curr_user)
    case user_invite_perms(curr_user)
    when 'owner'
      validate_admin_destroy(curr_user)
    when 'pending_invite', 'attendee'
      validate_user_destroy(curr_user)
    end
  end

  # runs validations on invite based on current user perms
  def validate_create_invite(curr_user)
    case user_invite_perms(curr_user)
    when 'owner'
      validate_owner_create(curr_user)
    when 'pending_invite', 'open_invite'
      validate_invited_create(curr_user)
      accept_valid_invite
    else
      add_perms_error
    end
  end

  def user_invite_perms(curr_user)
    perms = curr_user.event_perms(event_id)
    perms ||= 'open_invite' unless event.private
    perms
  end

  # if invited
  # current user but be invited user to create invite
  def validate_invited_create(curr_user)
    add_perms_error unless user_id == curr_user.id
  end

  def validate_owner_create(curr_user)
    add_perms_error if curr_user.id != event.creator_id
    add_perms_error if accepted == 'true'
  end

  def validate_admin_destroy(curr_user); end

  def validate_user_destroy(curr_user); end

  def destroy_valid_invite
    destroy if errors.empty?
  end

  def save_valid_invite
    save if errors.empty?
    self
  end

  def accept_valid_invite
    self.accepted = true if errors.empty?
  end

  def generate_create_error_text
    errors.full_messages.join(' ')
  end

  def generate_create_success_text
    if accepted
      'You are now attending the event.'
    else
      'Invite created.'
    end
  end

  private

  def add_perms_error
    errors.add :base, 'You do not have permission to perform this action'
  end
end
