class RemovePrivateFromEventsTable < ActiveRecord::Migration[7.0]
  def change
    remove_column :events, :private, :boolean
  end
end
