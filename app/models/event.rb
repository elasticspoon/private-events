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
end
