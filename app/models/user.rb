class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :events_created, class_name: 'Event', foreign_key: 'creator_id'

  has_many :user_event_permissions, dependent: :destroy
  has_many :event_relations, through: :user_event_permissions, source: :event

  validates :name, presence: true, length: { in: 3..20 }
  validates :username, uniqueness: true, length: { in: 5..20 }

  def events_attended
    user_event_permissions.where(permission_type: 'attend').includes(:event).map(&:event)
  end

  # Public Events: invite is extended but user has not yet accepted
  # Private Events: invite is extended but user has not yet accepted
  def events_pending
    user_event_permissions.where(permission_type: 'accept_invite').includes(:event).map(&:event)
  end

  # returns an array of permissions that the current user holds
  # for the prospective permission being acted on
  def held_event_perms(permssion_tar_event_id, curr_user_id)
    perms = user_event_permissions.where(event_id: permssion_tar_event_id).to_a.map(&:permission_type)
    id == curr_user_id ? perms << 'current_user' : perms
  end

  def holds_permission_currently?(permission_type, event_id)
    user_event_permissions.where(event_id: event_id, permission_type: permission_type).any?
  end
end
