class User < ApplicationRecord
  has_many :events_created, class_name: 'Event', foreign_key: 'creator_id'
  has_many :events_attended, through: :attended_events, source: :event
  has_many :attended_events
end
