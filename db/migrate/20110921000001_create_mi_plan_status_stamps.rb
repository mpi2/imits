class CreateMiPlanStatusStamps < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_status_stamps do |table|
      table.integer :mi_plan_id, :null => false
      table.integer :mi_plan_status_id, :null => false

      table.timestamps
    end

    remove_column :mi_plans, :mi_plan_status_id
  end

  def self.down
    add_column :mi_plans, :mi_plan_status_id, :integer, :null => false
    add_foreign_key :mi_plans, :mi_plan_statuses
    drop_table :mi_plan_status_stamps
  end
end
