class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :attended_events
  has_many :events_created, class_name: 'Event', foreign_key: 'creator_id'
  has_many :events_attended, through: :attended_events, source: :event
end
