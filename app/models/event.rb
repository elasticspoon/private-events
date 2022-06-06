class Event < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :attended_events, dependent: :destroy
  has_many :attendees, through: :attended_events, source: :user

  validates :date, presence: true
  validates :location, presence: true
  validates :creator_id, presence: true
  validates :name, presence: true
  validates :desc, presence: true
  validates :private, presence: true, allow_blank: true

  def self.past
    where('date < ?', DateTime.now)
  end

  def self.future
    where('date > ?', DateTime.now)
  end

  def future
    date > DateTime.now
  end

  def past
    date < DateTime.now
  end

  def accepted_invites
    User.find_by_sql(["
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE \"attended_events\".\"accepted\" = true AND event_id = ?", id])
  end

  def pending_invites
    User.find_by_sql(["
      SELECT * FROM users
      INNER JOIN attended_events ON attended_events.user_id = users.id
      INNER JOIN events ON attended_events.event_id = events.id
      WHERE \"attended_events\".\"accepted\" = false AND event_id = ?", id])
  end

  def event_color
    future ? ' bg-green-300 border-green-500' : ' bg-red-300 border-red-500'
  end
end
