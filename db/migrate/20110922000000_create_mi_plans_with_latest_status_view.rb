class CreateMiPlansWithLatestStatusView < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW mi_plans_with_latest_status AS
      SELECT mi_plans.*,
             (
               SELECT mi_plan_status_stamps.mi_plan_status_id
               FROM mi_plan_status_stamps
               WHERE mi_plan_status_stamps.mi_plan_id = mi_plans.id
               ORDER BY mi_plan_status_stamps.created_at DESC
               LIMIT 1
             ) latest_mi_plan_status_id
      FROM mi_plans;
    SQL
  end

  def self.down
    execute 'DROP VIEW mi_plans_with_latest_status'
  end
end
