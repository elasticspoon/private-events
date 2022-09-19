class RemoveAttendeePrivacyFromEvents < ActiveRecord::Migration[7.0]
  def change
    remove_column :events, :attendee_privacy, :string
  end
end
