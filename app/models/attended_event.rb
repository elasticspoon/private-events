class AttendedEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id
  validates :event_id
end
