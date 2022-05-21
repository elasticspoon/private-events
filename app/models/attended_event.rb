class AttendedEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user, uniqueness: { scope: :event, message: 'Invite already exists' }
  validates :accepted, inclusion: [true, false]
  # validate :attendance

  def self.accept_or_create_invite(updated_params, current_user_id)
    return AttendedEvent.new(updated_params).check_invite_perms(current_user_id) unless updated_params[:accepted]

    created_invite = AttendedEvent.find_by(user_id: updated_params[:user_id],
                                           event_id: updated_params[:event_id]) || AttendedEvent.new(updated_params)

    created_invite.check_attendance_perms(current_user_id)
  end

  def check_attendance_perms(current_user_id)
    event.private ? accept_private_invite(current_user_id) : accept_public_invite(current_user_id)
  end

  def accept_public_invite(current_user_id)
    errors.add :accepted, message: 'Invite already exists.' unless new_record? || accepted == false
    errors.add :accepted, message: 'You do not have the required permissions.' if current_user_id != user.id

    if errors.empty?
      self.accepted = true
      save
    end

    self
  end

  def accept_private_invite(current_user_id)
    errors.add :accepted, message: 'Invite does not exist.' if new_record?
    errors.add :accepted, message: 'You do not have the required permissions.' if current_user_id != user.id

    if errors.empty?
      self.accepted = true
      save
    end

    self
  end

  def check_invite_perms(current_user_id)
    errors.add :accepted, message: 'You do not have the required permissions.' if current_user_id != event.creator_id

    save if errors.empty?
    self
  end
end
