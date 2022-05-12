class RenameInviteToAcceptedAttendedEvents < ActiveRecord::Migration[7.0]
  def change
    rename_column :attended_events, :invite?, :accepted?
  end
end
