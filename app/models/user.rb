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

  # Public Events: user has chosen to attend event: accepted is NULL
  # Private Events: user has accepted invite to event: accepted is true
  def events_attended
    Event.find_by_sql('
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE "attended_events"."accepted" IS NULL OR "attended_events"."accepted" IS true')
  end

  # Public Events: does not apply, will be 0
  # Private Events: invite is extended but user has not yet accepted
  def events_pending
    Event.find_by_sql(["
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE \"attended_events\".\"accepted\" = false AND user_id = ?", id])
  end
end
