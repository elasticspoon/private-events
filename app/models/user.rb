class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :attended_events
  has_many :events_created, class_name: 'Event', foreign_key: 'creator_id'

  # Public Events: events a user has signed up for
  # Private Events: events to which a user is invited, whether or not they have accepted
  has_many :events_invited, through: :attended_events, source: :event

  validates :name, presence: true, length: { in: 3..20 }
  validates :username, uniqueness: true, length: { in: 5..20 }

  def events_attended
    Event.find_by_sql(["
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE \"attended_events\".\"accepted\" = true AND user_id = ?", id])
  end

  # Public Events: invite is extended but user has not yet accepted
  # Private Events: invite is extended but user has not yet accepted
  def events_pending
    Event.find_by_sql(["
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE \"attended_events\".\"accepted\" = false AND user_id = ?", id])
  end

  def event_id_attending?(event_id)
    events_attended.map(&:id).include?(event_id)
  end

  def event_id_pending?(event_id)
    events_pending.map(&:id).include?(event_id)
  end

  def event_id_invited?(event_id)
    events_invited_ids.include?(event_id)
  end

  def event_perms(event_id)
    return 'owner' if events_created_ids.include?(event_id)
    return 'attendee' if event_id_attending?(event_id)
    return 'pending_invite' if event_id_pending?(event_id)
  end
end
