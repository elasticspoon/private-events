class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.datetime :date
      t.string :location
      t.references :creator, null: false, foreign_key: true

      t.timestamps
    end
  end
end
