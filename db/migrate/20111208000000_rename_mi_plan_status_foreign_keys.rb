class RenameMiPlanStatusForeignKeys < ActiveRecord::Migration
  def self.up
    rename_column :mi_plans, :mi_plan_status_id, :status_id
    rename_column :mi_plan_status_stamps, :mi_plan_status_id, :status_id
  end

  def self.down
    rename_column :mi_plan_status_stamps, :status_id, :mi_plan_status_id
    rename_column :mi_plans, :status_id, :mi_plan_status_id
  end
end
