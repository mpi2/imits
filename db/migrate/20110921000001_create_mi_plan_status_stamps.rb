class CreateMiPlanStatusStamps < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_status_stamps do |table|
      table.integer :mi_plan_id, :null => false
      table.integer :mi_plan_status_id, :null => false

      table.timestamps
    end
  end

  def self.down
    drop_table :mi_plan_status_stamps
  end
end
