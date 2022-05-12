class RenameAcceptedToRemovePunctuationAttendedEvents < ActiveRecord::Migration[7.0]
  def change
    rename_column :attended_events, :accepted?, :accepted
  end
end
