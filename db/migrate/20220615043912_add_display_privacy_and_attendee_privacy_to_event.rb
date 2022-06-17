class AddDisplayPrivacyAndAttendeePrivacyToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :display_privacy, :string
    add_column :events, :attendee_privacy, :string
  end
end
