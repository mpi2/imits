class CreateTrackingGoals < ActiveRecord::Migration
  def up
    create_table :tracking_goals do |t|
      t.integer :production_centre_id
      t.date    :date
      t.string  :goal_type
      t.integer :goal

      t.timestamps
    end
  end

  def down
    drop_table :tracking_goals
  end
end
