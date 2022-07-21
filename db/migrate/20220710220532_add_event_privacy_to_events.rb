class AddEventPrivacyToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :event_privacy, :string
  end
end
