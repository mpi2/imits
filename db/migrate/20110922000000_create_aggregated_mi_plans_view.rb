class CreateAggregatedMiPlansView < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW aggregated_mi_plans AS
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
    execute 'DROP VIEW aggregated_mi_plans'
  end
end
