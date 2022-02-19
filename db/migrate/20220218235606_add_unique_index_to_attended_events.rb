class AddUniqueIndexToAttendedEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :attended_events, %i[user_id event_id], unique: true
  end
end
