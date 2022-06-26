class AttendedEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user, uniqueness: { scope: :event, message: 'Invite already exists' }
  validates :accepted, inclusion: [true, false]

  #######################################################################
  # Destroy Invite Methods
  #######################################################################

  def self.destroy_invite(u_id, e_id, current_u_id)
    u_id ||= current_u_id
    invite = AttendedEvent.find_by(user_id: u_id, event_id: e_id) || AttendedEvent.new
    invite.validate_destroy_invite(current_u_id)
    invite.destroy_valid_invite

    invite.generate_destroy_error_text
  end

  def validate_destroy_invite(current_u_id)
    (errors.add(:alert, 'That invitation does not exist.') and return) if new_record?
    (errors.add(:notice, 'You are no longer attending.') and return) if current_u_id == user_id
    (errors.add(:notice, 'Invite revoked.') and return) if current_u_id == event.creator_id
    errors.add(:alert, 'You do not have permission.')
  end

  def destroy_valid_invite
    destroy if errors[:alert].empty?
  end

  def generate_destroy_error_text
    errs = errors.to_hash.first
    errors.clear
    errs
  end

  #######################################################################
  # Create Invite Methods
  #######################################################################

  def self.process_invite(params, current_u_id)
    existing_invite = AttendedEvent.find_by(user_id: params[:user_id], event_id: params[:event_id])
    created_invite = existing_invite || AttendedEvent.new(params)

    if params[:accepted]
      created_invite.validate_accepted_invite(current_u_id)
      created_invite.accept_valid_invite
    else
      created_invite = existing_invite ? AttendedEvent.new(params) : existing_invite
      created_invite.validate_invite_creation(current_u_id)
    end

    created_invite.save_valid_invite
  end

  def validate_accepted_invite(current_u_id)
    event.private ? validate_private_invite(current_u_id) : validate_public_invite(current_u_id)
  end

  def validate_invite_creation(current_u_id)
    errors.add :base, message: 'You do not have the required permissions.' if current_u_id != event.creator_id
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

  def validate_public_invite(current_u_id)
    errors.add :base, message: 'Invite already exists.' unless new_record? || accepted == false
    errors.add :base, message: 'You do not have the required permissions.' if current_u_id != user.id
  end

  def validate_private_invite(current_u_id)
    errors.add :accepted, message: 'Invite does not exist.' if new_record?
    errors.add :accepted, message: 'You do not have the required permissions.' if current_u_id != user.id
  end
end
