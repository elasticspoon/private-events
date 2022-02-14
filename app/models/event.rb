class Event < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :attendees, through: :attendedevents, source: :user
  has_many :attendedevents

  validates :date
  validates :location
  validates :creator_id
end
