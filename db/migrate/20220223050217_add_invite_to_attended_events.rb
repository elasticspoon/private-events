class AddInviteToAttendedEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :attended_events, :invite?, :boolean
  end
end
