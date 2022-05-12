class AttendedEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  attr_accessor :current_user_id

  validates :user_id, presence: true
  validates :event_id, presence: true
  # validates :user, uniqueness: { scope: :event }
  # validates :accepted?, presence: true, if: :private_event
  validate :attendance

  def public_invite(invite)
    errors.add :accepted, 'already exists' if invite
  end

  def private_invite(invite, event)
    p invite.inspect
    p event.inspect
    p current_user_id
    p invite&.accepted
    p user_id

    if invite.nil? && event.creator_id == current_user_id
      update_attribute(:accepted, false)
      return
    end
    if invite&.accepted? == false && user_id == current_user_id
      update_attribute(:accepted, true)
      return
    end

    errors.add :accepted, 'Not valid'
  end

  def attendance
    invite = AttendedEvent.find_by(event_id: event_id, user_id: user_id)
    event = Event.find(event_id)
    p event.inspect
    return private_invite(invite, event) if event&.private
    return public_invite(invite) if event&.private == false
  end
end
