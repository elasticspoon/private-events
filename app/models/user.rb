class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :events_created, class_name: 'Event', foreign_key: 'creator_id', dependent: :destroy, inverse_of: :creator

  has_many :user_event_permissions, dependent: :destroy
  has_many :event_relations, through: :user_event_permissions, source: :event

  # TODO: maybe this needs eager loading?
  has_many :events_attended_perms, -> { where permission_type: 'attend' }, class_name: 'UserEventPermission'
  has_many :events_attended, through: :events_attended_perms, source: :event

  has_many :events_pending_perms, -> { where permission_type: 'accept_invite' }, class_name: 'UserEventPermission'
  has_many :events_pending, through: :events_pending_perms, source: :event

  validates :name, presence: true, length: { in: 3..30 }
  validates :username, presence: true, uniqueness: true, length: { minimum: 5 }

  # def events_attended
  #   user_event_permissions.where(permission_type: 'attend').includes(:event).map(&:event)
  # end

  # def events_pending
  #   user_event_permissions.where(permission_type: 'accept_invite').includes(:event).map(&:event)
  # end

  def attending?(event_id)
    holds_permission_currently?(event_id, 'attend')
  end

  def invite?(event_id)
    holds_permission_currently?(event_id, 'accept_invite')
  end

  def can_moderate?(event_id)
    holds_permission_currently?(event_id, 'moderate', 'owner')
  end

  def can_edit?(event_id)
    holds_permission_currently?(event_id, 'owner')
  end

  def can_join?(event)
    return false if attending?(event.id)
    return true if event.event_privacy == 'public' || event.event_privacy == 'protected'

    holds_permission_currently?(event.id, 'accept_invite', 'moderate', 'owner')
  end

  # returns an array of permissions that the current user holds
  # for the prospective permission being acted on
  # assumes event_id is valid
  def self.held_event_perms(user, event_id)
    return nil if user.nil?

    user.user_event_permissions.where(event_id:).pluck(:permission_type)
  end

  private

  def holds_permission_currently?(event_id, *permission_type)
    user_event_permissions.where(event_id:, permission_type:).any?
  end
end
