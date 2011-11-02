class AddMiPlanStatusStampForeignKeys < ActiveRecord::Migration
  def self.up
    add_foreign_key :mi_plan_status_stamps, :mi_plans
    add_foreign_key :mi_plan_status_stamps, :mi_plan_statuses
  end

  def self.down
    remove_foreign_key :mi_plan_status_stamps, :mi_plans
    remove_foreign_key :mi_plan_status_stamps, :mi_plan_statuses
  end
end
