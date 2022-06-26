class Event < ApplicationRecord
  AVAILIABLE_SETTINGS = %w[private protected public].freeze

  belongs_to :creator, class_name: 'User'
  has_many :attended_events, dependent: :destroy
  has_many :attendees, through: :attended_events, source: :user

  validates :date, presence: true
  validates :location, presence: true
  validates :creator_id, presence: true
  validates :name, presence: true
  validates :desc, presence: true
  validates :private, presence: true, allow_blank: true
  validates :display_privacy, inclusion: AVAILIABLE_SETTINGS
  validates :attendee_privacy, inclusion: AVAILIABLE_SETTINGS

  def self.past
    where('date < ?', DateTime.now)
  end

  def self.future
    where('date > ?', DateTime.now)
  end

  def self.display_public
    where(display_privacy: 'public')
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

  def attendee_perms_display?(current_user)
    return true if attendee_privacy == 'public'
    return true if attendee_privacy == 'protected' && current_user.event_id_invited?(id)
    return true if current_user&.id == creator_id

    false
  end

  def user_perms_display?(current_user)
    return true if display_privacy == 'public'
    return true if display_privacy == 'protected' && current_user.event_id_invited?(id)
    return true if current_user&.id == creator_id

    false
  end

  def user_perms_view?(current_user)
    return true unless private
    return true if private && current_user.event_id_invited?(id)
    return true if current_user&.id == creator_id

    false
  end
end
