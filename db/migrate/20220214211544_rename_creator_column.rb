class RenameCreatorColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :events, :creator, :creator_id
  end
end
