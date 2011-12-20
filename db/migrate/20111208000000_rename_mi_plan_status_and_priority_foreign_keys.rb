class RenameMiPlanStatusAndPriorityForeignKeys < ActiveRecord::Migration
  def self.up
    rename_column :mi_plans, :mi_plan_status_id, :status_id
    rename_column :mi_plan_status_stamps, :mi_plan_status_id, :status_id
    rename_column :mi_plans, :mi_plan_priority_id, :priority_id
  end

  def self.down
    rename_column :mi_plans, :priority_id, :mi_plan_priority_id
    rename_column :mi_plan_status_stamps, :status_id, :mi_plan_status_id
    rename_column :mi_plans, :status_id, :mi_plan_status_id
  end
end
